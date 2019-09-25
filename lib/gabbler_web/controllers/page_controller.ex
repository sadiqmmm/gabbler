defmodule GabblerWeb.PageController do
  use GabblerWeb, :controller

  plug Gabbler.Plug.UserSession
  

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
