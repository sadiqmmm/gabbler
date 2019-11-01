defmodule GabblerWeb.RoomController do
  use GabblerWeb, :controller

  import Phoenix.LiveView.Controller

  alias GabblerData.Query.Room, as: QueryRoom

  plug Gabbler.Plug.UserSession

  def new(conn, params) do
    live_render(conn, GabblerWeb.Live.Room.New, session: params)
  end

  def room(%{assigns: %{user: user}} = conn, %{"room" => name, "mode" => "live"}) do
    case QueryRoom.get(name) do
      nil ->
        room_404(conn)

      room ->
        live_render(conn, GabblerWeb.Live.Room.Index,
          session: %{room: room, user: user, mode: :live}
        )
    end
  end

  def room(%{assigns: %{user: user}} = conn, %{"room" => name, "mode" => "new"}) do
    case QueryRoom.get(name) do
      nil ->
        room_404(conn)

      room ->
        live_render(conn, GabblerWeb.Live.Room.Index,
          session: %{room: room, user: user, mode: :new}
        )
    end
  end

  def room(%{assigns: %{user: user}} = conn, %{"room" => name}) do
    case QueryRoom.get(name) do
      nil -> room_404(conn)
      room -> live_render(conn, GabblerWeb.Live.Room.Index, session: %{room: room, user: user})
    end
  end

  def room(conn, _), do: room_404(conn)

  defp room_404(conn),
    do:
      conn
      |> put_status(:not_found)
      |> render(GabblerWeb.ErrorView, "404.html")
end
