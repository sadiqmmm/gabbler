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
  defp init(%{:room => room, :post => post}, socket) do
    user = User.mock_data()

    assign(socket,
      post: post,
      post_meta: %PostMeta{},
      comments: [],
      room: room,
      room_type: "room",
      user: user,
      post_user: user,
      parent: nil,
      mod: false)
  end
end