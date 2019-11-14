defmodule GabblerWeb.Live.House.All do
  @moduledoc """
  Liveview for the house All page
  """
  use GabblerWeb.Live.Auth, auth_required: ["vote"]
  use GabblerWeb.Live.Voting
  use Phoenix.LiveView


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PageView, "index.html", assigns) %>
    """
  end

  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  # PRIVATE FUNCTIONS
  ###################
  defp init(%{posts: posts, post_metas: post_metas, users: users, rooms: rooms, user: user}, socket) do
    assign(socket, 
      posts: posts,
      post_metas: post_metas,
      users: users,
      rooms: rooms,
      user: user)
  end
end