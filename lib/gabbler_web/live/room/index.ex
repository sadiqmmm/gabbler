defmodule GabblerWeb.Live.Room.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerWeb.Presence
  alias GabblerData.{Room, User}
  alias GabblerData.Query.Post, as: QueryPost


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "sidebar.html", %{room: @room, user: @user, mod: false, user_count: @user_count}) %>
    """
  end

  def handle_info(%{event: "new_post", payload: %{post: post, meta: meta}}, %{assigns: %{posts: posts, post_metas: metas}} = socket) do
    {:noreply, assign(socket, posts: [post|posts], post_metas: Map.put(metas, post.id, meta))}
  end

  def handle_info(%{event: "presence_diff", payload: _}, %{assigns: %{room: %{name: name}}} = socket) do
    user_count = Presence.list("room:#{name}")
    |> Enum.count()

    {:noreply, assign(socket, user_count: user_count)}
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  # PRIV
  #############################
  defp init(%{room: %{name: name} = room, mode: mode, posts: posts}, socket) do
    user = User.mock_data()

    Presence.track(self(), "room:#{name}", user.id, %{name: user.name})

    user_count = Presence.list("room:#{name}")
    |> Enum.count()

    assign(socket,
      room: room,
      room_type: "room",
      posts: posts,
      mode: mode,
      post_metas: QueryPost.map_meta(posts),
      user: user,
      user_count: user_count
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

  defp init(_, socket) do
    assign(socket,
      room: %Room{type: "public", age: 0},
      room_type: "room",
      posts: [],
      post_metas: %{},
      user: User.mock_data()
    )
  end
end