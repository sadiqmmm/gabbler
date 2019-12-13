defmodule GabblerWeb.Live.Post.Index do
  @moduledoc """
  The Post Page LiveView
  """
  use GabblerWeb.Live.Auth, auth_required: ["reply", "reply_submit", "reply_comment", "vote", "subscribe"]
  use GabblerWeb.Live.Voting
  use GabblerWeb.Live.Room
  use GabblerWeb.Live.Konami, timeout: 5000
  use Phoenix.LiveView

  alias Gabbler.{PostCreation, PostRemoval}
  alias GabblerWeb.Presence
  alias GabblerData.{User, Post, PostMeta, Comment, Room}

  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PostView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", assigns) %>
    """
  end

  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  def handle_info(
        %{event: "new_reply", payload: %{post: comment}},
        %{assigns: %{op: op, comments: comments}} = socket
      ) do
    assign(socket,
      comments: add_comment(op, comment, comments),
      pages: query(:post).page_count(op)
    )
    |> no_reply()
  end

  def handle_event("reply", %{"to" => _}, %{assigns: %{post: %{id: post_id}}} = socket) do
    socket
    |> update_changeset(:changeset_reply, :reply, :parent_id, post_id)
    |> assign(reply_display: "block")
    |> no_reply()
  end

  def handle_event(
        "page_up",
        _,
        %{assigns: %{post: post, mode: mode, page: current_page}} = socket
      ) do
    page = current_page + 1

    comments = query(:post).thread(post, mode, page)

    assign(socket, page: page, comments: comments)
    |> no_reply()
  end

  def handle_event(
        "page_down",
        _,
        %{assigns: %{post: post, mode: mode, page: current_page}} = socket
      ) do
    page = current_page - 1

    comments = query(:post).thread(post, mode, page)

    assign(socket, page: page, comments: comments)
    |> no_reply()
  end

  def handle_event("reply", _, socket), do: no_reply(socket)

  def handle_event("reply_comment", %{"to" => parent_hash}, socket) do
    %{id: post_id} = query(:post).get(parent_hash)

    socket
    |> update_changeset(:changeset_reply, :reply, :parent_id, post_id)
    |> assign(reply_comment_display: "block")
    |> no_reply()
  end

  def handle_event("reply_hide", _, socket), do: assign(socket, reply_display: "hidden")
  |> no_reply()

  def handle_event("reply_comment_hide", _, socket), do: assign(socket, reply_comment_display: "hidden")
  |> no_reply()

  def handle_event(
        "reply_change",
        %{"_target" => ["reply", "body"], "reply" => %{"body" => body}},
        socket
      ) do
    update_changeset(socket, :changeset_reply, :reply, :body, body)
    |> no_reply()
  end

  def handle_event(
        "reply_submit",
        _,
        %{
          assigns: %{
            user: user,
            op: %{hash: op_hash} = op,
            room: room,
            changeset_reply: changeset,
            comments: comments
          }
        } = socket
      ) do
    case query(:post).create_reply(PostCreation.prepare_changeset(room, changeset)) do
      {:ok, comment} ->
        GabblerWeb.Endpoint.broadcast("post_live:#{op_hash}", "new_reply", %{:post => comment})

        post = query(:post).get(comment.parent_id)

        _ = Gabbler.User.add_activity(post.user_id_post, post.id, "reply")

        assign(socket,
          changeset_reply: default_reply_changeset(user, room, op),
          reply: default_reply(user, room, op),
          reply_display: "hidden",
          reply_comment_display: "hidden",
          comments: add_comment(op, comment, comments)
        )

      {:error, changeset} ->
        assign(socket, changeset_reply: changeset)
    end
    |> no_reply()
  end

  def handle_event("post_edit", %{"hash" => _hash, "body" => _body}, socket) do
    no_reply(socket)
  end

  def handle_event("hide_thread", %{"id" => hide_id}, %{assigns: %{comments: comments}} = socket) do
    hide_id = String.to_integer(hide_id)

    # Hide post and posts beneath it within it's thread
    {comments, _, _} =
      Enum.reduce(comments, {[], false, 0}, fn %{id: id, depth: depth} = comment,
                                               {acc, in_thread, at_depth} ->
        if id == hide_id || (in_thread && depth > at_depth) do
          {acc, true, depth}
        else
          {[comment | acc], false, at_depth}
        end
      end)

    assign(socket, comments: Enum.reverse(comments))
    |> no_reply()
  end

  def handle_event("delete_post", %{"hash" => hash}, %{assigns: %{user: user}} = socket) do
    socket
    |> state_update_post(PostRemoval.moderator_removal(user, hash))
    |> no_reply()
  end

  # PRIV
  #############################
  defp init(%{:mode => "hot"} = session, socket), do: init(Map.put(session, :mode, :hot), socket)
  defp init(%{:mode => "new"} = session, socket), do: init(Map.put(session, :mode, :new), socket)

  defp init(%{:mode => "live", :post => %{:hash => op_hash}} = session, socket) do
    GabblerWeb.Endpoint.subscribe("post_live:#{op_hash}")

    init(Map.put(session, :mode, :new), socket)
  end

  defp init(
         %{post: post, mode: mode, op: op, focus_hash: focus_hash},
         %{assigns: %{room: room, user: user}} = socket
       ) do
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
      reply_display: "hidden",
      reply_comment_display: "hidden",
      page: 1,
      pages: query(:post).page_count(post),
      focus_hash: focus_hash,
      changeset_reply: default_reply_changeset(user, room, post),
      reply: default_reply(user, room, post)
    )
  end

  defp init(%{post: post, mode: _} = session, socket) do
    init(Map.put(session, :op, post), socket)
  end

  defp init(session, socket), do: init(%{session | :mode => :hot}, socket)

  defp add_comment(%{id: op_id}, %{parent_id: parent_id} = new_comment, comments) do
    if op_id == parent_id do
      [new_comment | comments]
    else
      Enum.reverse(
        Enum.reduce(comments, [], fn comment, acc ->
          case comment do
            %{id: id, depth: depth} when id == parent_id ->
              [Map.put(new_comment, :depth, depth + 1), comment | acc]

            _ ->
              [comment | acc]
          end
        end)
      )
    end
  end

  defp default_reply_changeset(%User{} = user, %Room{} = room, %Post{} = post) do
    Comment.changeset(default_reply(user, room, post))
  end

  defp default_reply_changeset(nil, _, _), do: nil

  defp default_reply(%User{id: user_id}, %Room{id: room_id}, %Post{id: op_id, hash: op_hash}),
    do: %Comment{
      title: "reply",
      room_id: room_id,
      parent_id: op_id,
      parent_type: "comment",
      user_id_post: user_id,
      age: 0,
      hash_op: op_hash,
      score_public: 1,
      score_private: 1,
      score_alltime: 1
    }

  defp default_reply(nil, _, _), do: nil

  defp state_update_post(socket, {:ok, post}), do: state_update_post(socket, post)

  defp state_update_post(
         %{assigns: %{op: op, comments: comments}} = socket,
         %{id: id, body: body} = post
       ) do
    if op.id == id do
      assign(socket, op: post)
    else
      comments =
        Enum.map(comments, fn %{id: c_id} = comment ->
          if c_id == id do
            %{comment | body: body, score_public: 0}
          else
            comment
          end
        end)

      assign(socket, comments: comments)
    end
  end
end
