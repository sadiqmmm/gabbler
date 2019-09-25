defmodule GabblerWeb.PostController do
  use GabblerWeb, :controller

  alias GabblerData.Query.Room, as: QueryRoom
  alias GabblerData.Query.Post, as: QueryPost

  plug Gabbler.Plug.UserSession


  def new(conn, %{"room" => name}) do
    case QueryRoom.get(name) do
      nil -> post_404(conn)
      room -> live_render(conn, GabblerWeb.Live.Post.New, session: %{room: room})
    end
  end

  def post(conn, %{"room" => name, "hash" => hash}) do
    case {QueryRoom.get(name), QueryPost.get(hash)} do
      {room, post} when is_nil(room) or is_nil(post) ->
        post_404(conn)
      {room, post} ->
        live_render(conn, GabblerWeb.Live.Post.Index, session: %{room: room, post: post})
    end
  end

  def post(conn, _), do: post_404(conn)

  defp post_404(conn), do: conn
  |> put_status(:not_found)
  |> render(GabblerWeb.ErrorView, "404.html")
end