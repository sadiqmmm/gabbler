defmodule GabblerWeb.Live.Room.New do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerData.Room

  def render(assigns) do
    Phoenix.View.render(GabblerWeb.RoomView, "create.html", assigns)
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
      changeset: Room.changeset(%Room{}),
      room: %Room{}, 
      status: nil, 
      room_type: "room",
      posts: [],
      conn: socket)
  end
end