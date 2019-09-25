defmodule GabblerWeb.Live.Room.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerData.{Room, User}
  alias GabblerData.Query.Post, as: QueryPost


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.UserView, "menu.html", %{room: @room, user: @user, mod: false}) %>
    """
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  # PRIV
  #############################
  defp init(%{room: %{id: id} = room}, socket) do
    posts = QueryPost.list(by_room: id, order_by: :score_public, limit: 20)

    assign(socket,
      room: room,
      room_type: "room",
      posts: posts,
      post_metas: QueryPost.map_meta(posts),
      user: User.mock_data()
    )
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