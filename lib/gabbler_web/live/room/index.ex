defmodule GabblerWeb.Live.Room.Index do
  @moduledoc """
  Liveview when someone is in a generic (non-special like tag tracker) room
  """
  use GabblerWeb.Live.Auth, auth_required: ["vote", "subscribe"]
  use GabblerWeb.Live.Room
  use GabblerWeb.Live.Voting
  use GabblerWeb.Live.Konami, timeout: 5000
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", assigns) %>
    """
  end

  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  def handle_info(
        %{event: "new_post", payload: %{post: post, meta: meta}},
        %{assigns: %{posts: posts, post_metas: metas}} = socket
      ) do
    assign(socket, posts: [post | posts], post_metas: Map.put(metas, post.id, meta))
    |> no_reply()
  end

  # PRIV
  #############################
  defp init(%{mode: mode, posts: posts, user: user}, socket) do
    assign(socket,
      posts: posts,
      mode: mode,
      post_metas: query(:post).map_meta(posts),
      user: user,
      users: query(:post).map_users(posts)
    )
  end

  defp init(%{posts: _} = session, %{assigns: %{room: _}} = socket),
    do: init(Map.put(session, :mode, :hot), socket)

  defp init(%{mode: :new} = session, %{assigns: %{room: %{id: id}}} = socket) do
    posts = query(:post).list(by_room: id, order_by: :inserted_at, limit: 20)

    init(Map.put(session, :posts, posts), socket)
  end

  defp init(%{mode: :live} = session, %{assigns: %{room: %{id: id, name: name}}} = socket) do
    posts = query(:post).list(by_room: id, order_by: :inserted_at, limit: 20)

    GabblerWeb.Endpoint.subscribe("room_live:#{name}")

    init(Map.put(session, :posts, posts), socket)
  end

  defp init(session, %{assigns: %{room: %{id: id}}} = socket) do
    posts = query(:post).list(by_room: id, order_by: :score_private, limit: 20)

    init(Map.put(session, :posts, posts), socket)
  end
end
