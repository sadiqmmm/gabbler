defmodule GabblerWeb.Live.User.Login do
  @moduledoc """
  Authentication live view to manage the ui based on a users status and actions
  """
  use Phoenix.LiveView
  import GabblerWeb.Live.Socket, only: [no_reply: 1, update_changeset: 5]

  alias GabblerData.User

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

  def handle_info(%{event: "login_show", payload: _}, socket),
    do:
      assign(socket, show_auth: true)
      |> no_reply()

  def handle_event("login_show", _, socket), do: no_reply(assign(socket, show_auth: true))
  def handle_event("login_hide", _, socket), do: no_reply(assign(socket, show_auth: false))

  def handle_event("login_mode", %{"mode" => "login"}, socket),
    do: no_reply(assign(socket, mode: :login))

  def handle_event("login_mode", %{"mode" => "register"}, socket),
    do: no_reply(assign(socket, mode: :register))

  def handle_event("login_mode", %{"mode" => "logout"}, socket),
    do: no_reply(assign(socket, mode: :logout))

  def handle_event(
        "login_change",
        %{"_target" => ["user", "username"], "user" => %{"username" => name}},
        socket
      ) do
    update_changeset(socket, :changeset_user, :user, :name, name)
    |> no_reply()
  end

  def handle_event(
        "login_change",
        %{"_target" => ["user", "password"], "user" => %{"password" => password}},
        socket
      ) do
    update_changeset(socket, :changeset_user, :user, :password_hash, password)
    |> no_reply()
  end

  def handle_event(
        "login_change",
        %{"_target" => ["user", "password_confirm"], "user" => %{"password_confirm" => password}},
        socket
      ) do
    update_changeset(socket, :changeset_user, :user, :password_hash_confirm, password)
    |> no_reply()
  end

  def handle_event(
        "login_change",
        %{"_target" => ["user", "email"], "user" => %{"email" => email}},
        socket
      ) do
    update_changeset(socket, :changeset_user, :user, :email, email)
    |> no_reply()
  end

  # PRIV
  #############################
  defp init(%{user: %User{} = user, csrf: csrf}, socket) do
    assign(socket,
      user: user,
      changeset_user: User.changeset(user),
      mode: :logout,
      show_auth: false,
      csrf: csrf
    )
  end

  defp init(%{temp_token: temp_token, csrf: csrf}, socket) do
    GabblerWeb.Endpoint.subscribe("user:#{temp_token}")

    assign(socket,
      user: %User{},
      changeset_user: User.changeset(%User{}),
      mode: :login,
      show_auth: false,
      csrf: csrf
    )
  end
end
