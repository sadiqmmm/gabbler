defmodule GabblerWeb.Live.Post.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerData.{User, PostMeta}
  #alias GabblerData.Query.Post, as: QueryPost


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

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  # PRIV
  #############################
  defp init(%{:room => %{name: room_name} = room, :post => post}, socket) do
    user = User.mock_data()

    Presence.track(self(), "room:#{room_name}", user.id, %{name: user.name})

    user_count = Presence.list("room:#{room_name}")
    |> Enum.count()

    assign(socket,
      post: post,
      post_meta: %PostMeta{},
      comments: [],
      room: room,
      room_type: "room",
      user: user,
      post_user: user,
      parent: nil,
      mod: false,
      user_count: user_count)
  end
end