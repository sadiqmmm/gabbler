defmodule GabblerWeb.UserController do
  use GabblerWeb, :controller

  plug Gabbler.Plug.UserSession

  alias GabblerData.User
  alias GabblerData.Query.User, as: QueryUser
  alias GabblerData.Query.Post, as: QueryPost
  alias GabblerData.Query.Room, as: QueryRoom
  alias Gabbler.Auth.Guardian
  

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def profile(conn, %{"username" => name}) do
    case QueryUser.get(name) do
      nil -> 
        user_404(conn)
      %{id: user_id} = user ->
        posts = QueryPost.list(by_user: user_id, order_by: :inserted_at)

        rooms = Enum.reduce(posts, %{}, fn %{id: post_id, room_id: room_id}, acc ->
          Map.put(acc, post_id, QueryRoom.get(room_id))
        end)

        render(conn, "profile.html", user: user, posts: posts, rooms: rooms, post_meta: QueryPost.map_meta(posts))
    end
  end

  def new(conn, %{"user" => %{"password" => pass, "password_confirm" => pass_conf, "username" => name}}) do
    case register(name, pass, pass_conf) do
      {:ok, user} -> handle_signin(conn, user)
      {:error, error} -> conn
        |> put_flash(:error, error)
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"user" => %{"password" => pass, "username" => name}}) do
    case login(name, pass) do
      {:ok, user} ->
        handle_signin(conn, user)
      {:error, error} -> conn
        |> put_flash(:error, error)
        |> redirect(to: "/")
    end
  end

  def delete(conn, %{}), do: conn
  |> Guardian.Plug.sign_out()
  |> redirect(to: "/")

  defp handle_signin(conn, user), do: conn
  |> put_session(:current_user, user)
  |> configure_session(renew: true)
  |> put_flash(:info, gettext("You are logged in!"))
  |> Guardian.Plug.sign_in(user)
  |> redirect(to: "/")

  defp register(name, pass, pass_conf) do
    changeset = User.changeset(%User{}, %{name: name, password_hash: pass, password_hash_confirm: pass_conf})

    QueryUser.create(changeset)
  end

  defp login(name, password) do
    QueryUser.authenticate(name, password)
  end

  defp user_404(conn), do: conn
  |> put_status(:not_found)
  |> render(GabblerWeb.ErrorView, "404.html")
end
