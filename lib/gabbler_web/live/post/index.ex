defmodule GabblerWeb.Live.Post.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use GabblerWeb.Live.Room
  use GabblerWeb.Live.Voting
  use Phoenix.LiveView
  import GabblerWeb.Live.UtilSocket, only: [update_assign: 5]
  import Gabbler, only: [query: 1]

  alias Gabbler.PostCreation
  alias GabblerWeb.Presence
  alias GabblerData.{User, Post, PostMeta, Comment, Room}


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PostView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", assigns) %>
    """
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
    %{id: post_id} = query(:post).get(parent_hash)

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

    case query(:post).create_reply(PostCreation.prepare_changeset(room, changeset)) do
      {:ok, comment} ->
        GabblerWeb.Endpoint.broadcast("post_live:#{op_hash}", "new_reply", %{:post => comment})

        post = query(:post).get(comment.parent_id)
        
        _ = Gabbler.User.add_activity(post.user_id_post, post.id, "reply")

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

  # PRIV
  #############################
  defp init(%{:mode => "hot"} = session, socket), do: init(Map.put(session, :mode, :hot), socket)
  defp init(%{:mode => "new"} = session, socket), do: init(Map.put(session, :mode, :new), socket)
  defp init(%{:mode => "live", :post => %{:hash => op_hash}} = session, socket) do
    GabblerWeb.Endpoint.subscribe("post_live:#{op_hash}")

    init(Map.put(session, :mode, :new), socket)
  end

  defp init(%{room: room, user: user, post: post, mode: mode, op: op, focus_hash: focus_hash}, socket) do
    post_user = query(:user).get(post.user_id_post)

    comments = query(:post).thread(post, mode)

    assign(socket,
      post: post,
      post_meta: %PostMeta{},
      op: op,
      mode: mode,
      comments: comments,
      post_user: post_user,
      parent: nil,
      mod: false,
      reply_display: "hidden",
      reply_comment_display: "hidden",
      focus_hash: focus_hash,
      changeset_reply: default_reply_changeset(user, room, post),
      reply: default_reply(user, room, post))
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