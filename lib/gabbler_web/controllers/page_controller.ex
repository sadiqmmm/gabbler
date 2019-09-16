defmodule GabblerWeb.PageController do
  use GabblerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
