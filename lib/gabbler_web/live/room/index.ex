defmodule GabblerWeb.Live.Room.Index do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerData.Room


  def render(assigns) do
    Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns)
  end

  @doc """
  Set default form and status of creation
  """
  def mount(_session, socket) do
    {:ok, init(socket)}
  end

  # PRIV
  #############################
  defp init(socket) do
    assign(socket,
      status: nil,
      room: %Room{},
      room_type: "room",
      posts: []
    )
  end
end