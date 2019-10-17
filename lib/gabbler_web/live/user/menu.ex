defmodule GabblerWeb.Live.User.Menu do
  @moduledoc """
  Authentication live view to manage the ui based on a users status and actions
  """
  use Phoenix.LiveView

  alias GabblerData.User


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.UserView, "menu.html", assigns) %>
    """
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  def handle_info(%{event: "subscribed", payload: %{"room_name" => name}}, %{assigns: %{user: user}} = socket) do
    subscriptions = Gabbler.User.activity_subscribed(user, name)

    {:noreply, assign(socket, subscriptions: subscriptions)}
  end

  def handle_info(%{event: "unsubscribed", payload: %{"room_name" => name}}, %{assigns: %{user: user}} = socket) do
    subscriptions = Gabbler.User.activity_unsubscribed(user, name)

    {:noreply, assign(socket, subscriptions: subscriptions)}
  end

  def handle_info(%{event: "warning", payload: %{msg: msg}}, socket) do
    {:noreply, socket}
  end

  def handle_event("login", _, %{assigns: %{temp_token: token}} = socket) do
    GabblerWeb.Endpoint.broadcast("user:#{token}", "login_show", %{})

    {:noreply, socket}
  end

  def handle_event("toggle_menu", _, %{assigns: %{menu_open: false}} = socket) do
    {:noreply, assign(socket, menu_open: true)}
  end

  def handle_event("toggle_menu", _, %{assigns: %{menu_open: true}} = socket) do
    {:noreply, assign(socket, menu_open: false)}
  end

  # PRIV
  #############################
  defp init(%{user: %User{id: id} = user}, socket) do
    GabblerWeb.Endpoint.subscribe("user:#{id}")

    assign(socket,
      user: user,
      menu_open: false,
      subscriptions: Gabbler.User.subscriptions(user),
      moderating: Gabbler.User.moderating(user),
      posts: Gabbler.User.posts(user)
    )
  end

  defp init(%{temp_token: temp_token}, socket) do
    assign(socket,
      user: nil,
      temp_token: temp_token,
      menu_open: false)
  end

  defp subscribe_room(%{assigns: %{subscriptions: subscriptions}} = socket, room_name) do
    case Map.get(subscriptions, "r#{room_name}") do
      nil ->
        assign(socket, 
          subscriptions: Map.put(subscriptions, "r#{room_name}", GabblerWeb.Endpoint.subscribe("room_live:#{room_name}")))
      :ok ->
        socket
      {:error, _error} ->
        socket
    end
  end

  defp subscribe_post(%{assigns: %{subscriptions: subscriptions}} = socket, hash) do
    case Map.get(subscriptions, "p#{hash}") do
      nil ->
        assign(socket, 
          subscriptions: Map.put(subscriptions, "p#{hash}", GabblerWeb.Endpoint.subscribe("post_live:#{hash}")))
      :ok ->
        socket
      {:error, _error} ->
        socket
    end
  end
end