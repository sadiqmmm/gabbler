defmodule GabblerWeb.PageController do
  use GabblerWeb, :controller

  plug Gabbler.Plug.UserSession

  alias GabblerData.Query.Post, as: QueryPost

  def index(conn, _params) do
    posts = QueryPost.list(order_by: :score_private, limit: 20, only: :op)

    render(conn, "index.html",
      posts: posts,
      post_metas: QueryPost.map_meta(posts),
      users: QueryPost.map_users(posts),
      rooms: QueryPost.map_rooms(posts)
    )
  end

  def tag_tracker(%{assigns: %{user: user}} = conn, _params) do
    live_render(conn, GabblerWeb.Live.TagTracker.Index, session: %{user: user})
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end
end
