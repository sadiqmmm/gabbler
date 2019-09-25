defmodule GabblerWeb.RoomController do
  use GabblerWeb, :controller

  import Phoenix.LiveView.Controller

  alias GabblerData.Query.Room, as: QueryRoom

  plug Gabbler.Plug.UserSession


  def new(conn, params) do
    live_render(conn, GabblerWeb.Live.Room.New, session: params)
  end

  def room(conn, %{"room" => name}) do
    case QueryRoom.get(name) do
      nil -> room_404(conn)
      room -> live_render(conn, GabblerWeb.Live.Room.Index, session: %{room: room})
    end
  end

  def room(conn, _), do: room_404(conn)

  defp room_404(conn), do: conn
  |> put_status(:not_found)
  |> render(GabblerWeb.ErrorView, "404.html")
end