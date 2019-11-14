defmodule GabblerWeb.PostController do
  use GabblerWeb, :controller

  alias Gabbler.Live, as: GabblerLive
  import Gabbler, only: [query: 1]

  plug Gabbler.Plug.UserSession


  def new(conn, %{"room" => name}) do
    case query(:room).get(name) do
      nil -> post_404(conn)
      room -> GabblerLive.render(conn, GabblerWeb.Live.Post.New, %{room: room})
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

  defp post_render(conn, %{room_name: name, hash: hash, mode: mode}) do
    # TODO: get this ugly looking logic into it's own module
    case {query(:room).get(name), query(:post).get(hash)} do
      {room, post} when is_nil(room) or is_nil(post) ->
        post_404(conn)

      {room, post} ->
        GabblerLive.render(conn, GabblerWeb.Live.Post.Index, %{
          room: room,
          post: post,
          mode: mode,
          focus_hash: nil
        })
    end
  end

  defp post_render(conn, %{room_name: name, hash: hash, focus_hash: focus_hash}) do
    # TODO: get this ugly looking logic into it's own module
    case {query(:room).get(name), query(:room).get(hash), query(:post).get(focus_hash)} do
      {room, op, post} when is_nil(room) or is_nil(op) or is_nil(post) ->
        post_404(conn)

      {room, op, post} ->
        GabblerLive.render(conn, GabblerWeb.Live.Post.Index, %{
          room: room,
          op: op,
          post: post,
          mode: :new,
          focus_hash: focus_hash
        })
    end
  end

  defp post_render(conn, %{room_name: name, hash: hash, mode: mode}) do
    case {query(:room).get(name), query(:post).get(hash)} do
      {room, post} when is_nil(room) or is_nil(post) ->
        post_404(conn)

      {room, post} ->
        GabblerLive.render(conn, GabblerWeb.Live.Post.Index, %{
          room: room,
          post: post,
          mode: mode,
          focus_hash: nil
        })
    end
  end

  defp post_render(conn, _), do: post_404(conn)

  defp post_404(conn),
    do:
      conn
      |> put_status(:not_found)
      |> render(GabblerWeb.ErrorView, "404.html")
end
