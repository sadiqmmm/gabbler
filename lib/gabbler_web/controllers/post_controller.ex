defmodule GabblerWeb.PostController do
  use GabblerWeb, :controller

  alias GabblerData.Query.Room, as: QueryRoom
  alias GabblerData.Query.Post, as: QueryPost

  plug Gabbler.Plug.UserSession

  def new(%{assigns: %{user: user}} = conn, %{"room" => name}) do
    case QueryRoom.get(name) do
      nil -> post_404(conn)
      room -> live_render(conn, GabblerWeb.Live.Post.New, session: %{user: user, room: room})
    end
  end

  def post(conn, %{"room" => name, "hash" => hash, "mode" => mode}) do
    post_render(conn, %{room_name: name, hash: hash, mode: mode})
  end

  def post(conn, %{"room" => _, "hash" => _} = params) do
    post(conn, Map.put(params, "mode", :hot))
  end

  def post(conn, _), do: post_404(conn)

  def comment(conn, %{"room" => name, "hash" => hash, "focushash" => focus_hash}) do
    post_render(conn, %{room_name: name, hash: hash, focus_hash: focus_hash})
  end

  defp post_render(%{assigns: %{user: user}} = conn, %{
         :room_name => name,
         :hash => hash,
         :mode => mode
       }) do
    case {QueryRoom.get(name), QueryPost.get(hash)} do
      {room, post} when is_nil(room) or is_nil(post) ->
        post_404(conn)

      {room, post} ->
        live_render(conn, GabblerWeb.Live.Post.Index,
          session: %{user: user, room: room, post: post, mode: mode, focus_hash: nil}
        )
    end
  end

  defp post_render(%{assigns: %{user: user}} = conn, %{
         :room_name => name,
         :hash => hash,
         :focus_hash => focus_hash
       }) do
    case {QueryRoom.get(name), QueryPost.get(hash), QueryPost.get(focus_hash)} do
      {room, op, post} when is_nil(room) or is_nil(op) or is_nil(post) ->
        post_404(conn)

      {room, op, post} ->
        live_render(conn, GabblerWeb.Live.Post.Index,
          session: %{
            user: user,
            room: room,
            op: op,
            post: post,
            mode: :new,
            focus_hash: focus_hash
          }
        )
    end
  end

  defp post_render(%{assigns: %{user: user}} = conn, %{
         :room_name => name,
         :hash => hash,
         :mode => mode
       }) do
    case {QueryRoom.get(name), QueryPost.get(hash)} do
      {room, post} when is_nil(room) or is_nil(post) ->
        post_404(conn)

      {room, post} ->
        live_render(conn, GabblerWeb.Live.Post.Index,
          session: %{user: user, room: room, post: post, mode: mode, focus_hash: nil}
        )
    end
  end

  defp post_render(conn, _), do: post_404(conn)

  defp post_404(conn),
    do:
      conn
      |> put_status(:not_found)
      |> render(GabblerWeb.ErrorView, "404.html")
end
