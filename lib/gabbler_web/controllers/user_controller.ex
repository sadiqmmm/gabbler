defmodule GabblerWeb.UserController do
  use GabblerWeb, :controller

  plug Gabbler.Plug.UserSession

  import Gabbler, only: [query: 1]

  alias GabblerData.User
  
  alias Gabbler.Auth.Guardian

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def profile(conn, %{"username" => name}) do
    case query(:user).get(URI.decode(name)) do
      nil ->
        user_404(conn)

      %{id: user_id} = user ->
        posts = query(:post).list(by_user: user_id, order_by: :inserted_at, only: :op)

        render(conn, "profile.html",
          user: user,
          posts: posts,
          rooms: query(:post).map_rooms(posts),
          post_metas: query(:post).map_meta(posts)
        )
    end
  end

  def new(conn, %{
        "user" => %{"password" => pass, "password_confirm" => pass_conf, "username" => name}
      }) do
    case register(name, pass, pass_conf) do
      {:ok, user} ->
        handle_signin(conn, user)

      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"user" => %{"password" => pass, "username" => name}}) do
    case login(name, pass) do
      {:ok, user} ->
        handle_signin(conn, user)

      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: "/")
    end
  end

  def delete(conn, %{}),
    do:
      conn
      |> Guardian.Plug.sign_out()
      |> redirect(to: "/")

  defp handle_signin(conn, user),
    do:
      conn
      |> put_session(:current_user, user)
      |> configure_session(renew: true)
      |> put_flash(:info, gettext("You are logged in!"))
      |> Guardian.Plug.sign_in(user)
      |> redirect(to: "/")

  defp register(name, pass, pass_conf) do
    changeset =
      User.changeset(%User{}, %{name: name, password_hash: pass, password_hash_confirm: pass_conf})

    query(:user).create(changeset)
  end

  defp login(name, password) do
    query(:user).authenticate(name, password)
  end

  defp user_404(conn),
    do:
      conn
      |> put_status(:not_found)
      |> render(GabblerWeb.ErrorView, "404.html")
end
