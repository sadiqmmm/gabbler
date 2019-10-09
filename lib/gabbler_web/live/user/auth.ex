defmodule GabblerWeb.Live.User.Auth do
  @moduledoc """
  Authentication live view to manage the ui based on a users status and actions
  """
  use Phoenix.LiveView
  import GabblerWeb.Live.UtilSocket, only: [update_assign: 5]

  alias GabblerData.User
  alias GabblerData.Query.User, as: QueryUser

  alias Gabbler.Auth.Guardian


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.UserView, "login.html", assigns) %>
    """
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  def handle_info(%{event: "login_show", payload: _}, socket) do
    {:noreply, assign(socket, show_auth: true)}
  end

  def handle_event("login_show", _, socket), do: {:noreply, assign(socket, show_auth: true)}
  def handle_event("login_hide", _, socket), do: {:noreply, assign(socket, show_auth: false)}
  def handle_event("login_mode", %{"mode" => "login"}, socket), do: {:noreply, assign(socket, mode: :login)}
  def handle_event("login_mode", %{"mode" => "register"}, socket), do: {:noreply, assign(socket, mode: :register)}
  def handle_event("login_mode", %{"mode" => "logout"}, socket), do: {:noreply, assign(socket, mode: :logout)}

  def handle_event("login_change", %{"_target" => ["user", "username"], "user" => %{"username" => name}}, socket) do
    {:noreply, update_assign(:changeset_user, :user, :name, name, socket)}
  end

  def handle_event("login_change", %{"_target" => ["user", "password"], "user" => %{"password" => password}}, socket) do
    {:noreply, update_assign(:changeset_user, :user, :password_hash, password, socket)}
  end

  def handle_event("login_change", %{"_target" => ["user", "password_confirm"], "user" => %{"password_confirm" => password}}, socket) do
    {:noreply, update_assign(:changeset_user, :user, :password_hash_confirm, password, socket)}
  end

  def handle_event("login_change", %{"_target" => ["user", "email"], "user" => %{"email" => email}}, socket) do
    {:noreply, update_assign(:changeset_user, :user, :email, email, socket)}
  end

  def handle_event("login", %{"user" => %{"password" => _, "password_confirm" => _}}, 
  %{assigns: %{changeset_user: changeset}} = socket) do
    {:noreply, register(socket, changeset)}
  end

  def handle_event("login", _, %{assigns: %{changeset_user: changeset}} = socket) do
    {:noreply, login(socket, changeset)}
  end

  def register(socket, changeset) do
    case QueryUser.create(changeset) do
      {:ok, user} ->
        {:ok, token, _full_claims} = Guardian.encode_and_sign(user)

        assign(socket, token: token)
      {:error, error} ->
        IO.inspect "REGISTER FAIL"
        IO.inspect error
        assign(socket, changeset_user: error)
    end
  end

  def login(socket, changeset) do
    name = case Ecto.Changeset.fetch_field(changeset, :name) do
      {:changes, name} -> name
      {:data, name} -> name
      _ -> nil
    end

    password = case Ecto.Changeset.fetch_field(changeset, :password_hash) do
      {:changes, password} -> password
      {:data, password} -> password
      _ -> nil
    end

    login(socket, name, password)
  end

  def login(socket, nil, _), do: socket
  def login(socket, _, nil), do: socket

  def login(socket, name, password) do
    case QueryUser.authenticate(name, password) do
      {:ok, user} ->
        Guardian.Plug.sign_in(socket, Guardian, user)
      {:error, error} ->
        IO.inspect "LOGIN FAIL"
        IO.inspect error
        assign(socket, changeset_user: error)
    end
  end

  def logout(socket, _) do
    #conn
    Guardian.Plug.sign_out(socket, Guardian)
    #|> redirect(to: "/login")

    #conn
    #|> put_flash(:info, "Welcome back!")
    #|> Guardian.Plug.sign_in(Guardian, user)
    #|> redirect(to: "/secret")
  end

  # PRIV
  #############################
  defp init(%{user: %User{id: id} = user}, socket) do
    GabblerWeb.Endpoint.subscribe("user:#{id}")

    assign(socket,
      user: user,
      changeset_user: User.changeset(user),
      mode: :login,
      show_auth: false
    )
  end

  defp init(%{temp_token: temp_token}, socket) do
    GabblerWeb.Endpoint.subscribe("user:#{temp_token}")

    assign(socket,
      user: %User{},
      changeset_user: User.changeset(%User{}),
      mode: :login,
      show_auth: false
    )
  end

  defp init(_, socket) do
    assign(socket,
      user: %User{},
      changeset_user: User.changeset(%User{}),
      mode: :login,
      show_auth: false
    )
  end
end