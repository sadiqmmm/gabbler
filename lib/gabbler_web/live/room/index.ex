defmodule GabblerWeb.Live.Room.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use GabblerWeb.Live.Room
  use GabblerWeb.Live.Voting
  use Phoenix.LiveView

  alias GabblerData.Query.Post, as: QueryPost


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", assigns) %>
    """
  end

  def handle_info(%{event: "new_post", payload: %{post: post, meta: meta}}, %{assigns: %{posts: posts, post_metas: metas}} = socket) do
    {:noreply, assign(socket, posts: [post|posts], post_metas: Map.put(metas, post.id, meta))}
  end

  # PRIV
  #############################
  defp init(%{mode: mode, posts: posts, user: user}, socket) do
    assign(socket,
      posts: posts,
      mode: mode,
      post_metas: QueryPost.map_meta(posts),
      user: user,
      users: QueryPost.map_users(posts)
    )
  end

  defp init(%{posts: _, room: _} = session, socket), do: init(Map.put(session, :mode, :hot), socket)

  defp init(%{room: %{id: id}, mode: :new} = session, socket) do
    posts = QueryPost.list(by_room: id, order_by: :inserted_at, limit: 20)

    init(Map.put(session, :posts, posts), socket)
  end

  defp init(%{room: %{id: id, name: name}, mode: :live} = session, socket) do
    posts = QueryPost.list(by_room: id, order_by: :inserted_at, limit: 20)

    GabblerWeb.Endpoint.subscribe("room_live:#{name}")

    init(Map.put(session, :posts, posts), socket)
  end

  defp init(%{room: %{id: id}} = session, socket) do
    posts = QueryPost.list(by_room: id, order_by: :score_private, limit: 20)

    init(Map.put(session, :posts, posts), socket)
  end
end