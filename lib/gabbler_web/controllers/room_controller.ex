defmodule GabblerWeb.RoomController do
  use GabblerWeb, :controller
  
  import Phoenix.LiveView.Controller


  def new(conn, _params) do
    live_render(conn, GabblerWeb.Live.Room.New, session: %{})
  end
end