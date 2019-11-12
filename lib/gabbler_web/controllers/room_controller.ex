defmodule GabblerWeb.RoomController do
  use GabblerWeb, :controller

  alias Gabbler.Live, as: GabblerLive
  alias GabblerData.Query.Room, as: QueryRoom

  plug Gabbler.Plug.UserSession

  def new(conn, params) do
    GabblerLive.render(conn, GabblerWeb.Live.Room.New, params)
  end

  def room(conn, %{"room" => name, "mode" => "live"}) do
    case QueryRoom.get(name) do
      nil ->
        room_404(conn)

      room ->
        GabblerLive.render(conn, GabblerWeb.Live.Room.Index, %{room: room, mode: :live})
    end
  end

  def room(conn, %{"room" => name, "mode" => "new"}) do
    case QueryRoom.get(name) do
      nil ->
        room_404(conn)

      room ->
        GabblerLive.render(conn, GabblerWeb.Live.Room.Index, %{room: room, mode: :new})
    end
  end

  def room(conn, %{"room" => name}) do
    case QueryRoom.get(name) do
      nil -> room_404(conn)
      room -> GabblerLive.render(conn, GabblerWeb.Live.Room.Index, %{room: room})
    end
  end

  def room(conn, _), do: room_404(conn)

  defp room_404(conn),
    do:
      conn
      |> put_status(:not_found)
      |> render(GabblerWeb.ErrorView, "404.html")
end
