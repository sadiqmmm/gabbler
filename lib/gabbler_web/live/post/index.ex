defmodule GabblerWeb.Live.Post.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView
  import GabblerWeb.Live.UtilSocket, only: [update_assign: 5]

  alias Gabbler.PostCreation
  alias GabblerWeb.Presence
  alias GabblerData.{User, Post, PostMeta, Comment, Room}
  alias GabblerData.Query.Post, as: QueryPost


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PostView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", %{room: @room, user: @user, mod: false, user_count: @user_count}) %>
    """
  end

  def handle_info(%{event: "presence_diff", payload: _}, %{assigns: %{room: %{name: name}}} = socket) do
    user_count = Presence.list("room:#{name}")
    |> Enum.count()

    {:noreply, assign(socket, user_count: user_count)}
  end

  def handle_info(%{event: "new_reply", payload: %{post: comment}}, %{assigns: %{op: op, comments: comments}} = socket) do
    {:noreply, assign(socket, comments: add_comment(op, comment, comments))}
  end

  def handle_event("reply", %{"to" => _}, %{assigns: %{post: %{id: post_id}}} = socket) do
    socket = update_assign(:changeset_reply, :reply, :parent_id, post_id, socket)

    {:noreply, assign(socket, reply_display: "block")}
  end

  def handle_event("reply", _, socket) do
    {:noreply, socket}
  end

  def handle_event("reply_comment", %{"to" => parent_hash}, socket) do
    %{id: post_id} = QueryPost.get(parent_hash)

    socket = update_assign(:changeset_reply, :reply, :parent_id, post_id, socket)

    {:noreply, assign(socket, reply_comment_display: "block")}
  end

  def handle_event("reply_hide", _, socket) do
    {:noreply, assign(socket, reply_display: "hidden")}
  end

  def handle_event("reply_comment_hide", _, socket) do
    {:noreply, assign(socket, reply_comment_display: "hidden")}
  end

  def handle_event("reply_change", %{"_target" => ["reply", "body"], "reply" => %{"body" => body}}, socket) do
    {:noreply, update_assign(:changeset_reply, :reply, :body, body, socket)}
  end

  def handle_event("reply_submit", _, %{assigns: %{
    user: user, op: %{hash: op_hash} = op, room: room, changeset_reply: changeset, comments: comments}} = socket) do

    case QueryPost.create_reply(PostCreation.prepare_changeset(room, changeset)) do
      {:ok, comment} ->
        GabblerWeb.Endpoint.broadcast("post_live:#{op_hash}", "new_reply", %{:post => comment})

        {:noreply, assign(socket, 
          changeset_reply: default_reply_changeset(user, room, op), 
          reply: default_reply(user, room, op),
          reply_display: "hidden",
          reply_comment_display: "hidden",
          comments: add_comment(op, comment, comments))}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset_reply: changeset)}
    end
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  # PRIV
  #############################
  defp init(%{:mode => "hot"} = session, socket), do: init(Map.put(session, :mode, :hot), socket)
  defp init(%{:mode => "new"} = session, socket), do: init(Map.put(session, :mode, :new), socket)
  defp init(%{:mode => "live", :post => %{:hash => op_hash}} = session, socket) do
    GabblerWeb.Endpoint.subscribe("post_live:#{op_hash}")

    init(Map.put(session, :mode, :hot), socket)
  end

  defp init(%{room: %{name: room_name, type: room_type} = room, post: post, mode: mode, op: op, focus_hash: focus_hash}, socket) do
    user = User.mock_data()

    Presence.track(self(), "room:#{room_name}", user.id, %{name: user.name})

    user_count = Presence.list("room:#{room_name}")
    |> Enum.count()

    comments = QueryPost.thread(post, mode)

    assign(socket,
      post: post,
      post_meta: %PostMeta{},
      op: op,
      mode: mode,
      comments: comments,
      room: room,
      room_type: room_type,
      user: user,
      post_user: user,
      parent: nil,
      mod: false,
      reply_display: "hidden",
      reply_comment_display: "hidden",
      focus_hash: focus_hash,
      changeset_reply: default_reply_changeset(user, room, post),
      reply: default_reply(user, room, post),
      user_count: user_count)
  end

  defp init(%{room: _, post: post, mode: _} = session, socket), do: init(Map.put(session, :op, post), socket)

  defp init(session, socket), do: init(%{session | :mode => :hot}, socket)

  defp add_comment(%{id: op_id}, %{parent_id: parent_id} = new_comment, comments) do
    if op_id == parent_id do
      [new_comment|comments]
    else
      Enum.reverse(Enum.reduce(comments, [], fn comment, acc ->
        case comment do
          %{id: id, depth: depth} when id == parent_id ->
            [Map.put(new_comment, :depth, depth + 1), comment|acc]
          _ -> 
            [comment|acc]
        end
      end))
    end
  end

  defp default_reply_changeset(%User{} = user, %Room{} = room, %Post{} = post) do
    Comment.changeset(default_reply(user, room, post))
  end

  defp default_reply(%User{id: user_id}, %Room{id: room_id}, %Post{id: op_id, hash: op_hash}), do: %Comment{
    title: "reply", 
    room_id: room_id,
    parent_id: op_id,
    parent_type: "comment",
    user_id_post: user_id,
    age: 0,
    hash_op: op_hash,
    score_public: 1,
    score_private: 1,
    score_alltime: 1}
end