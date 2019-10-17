defmodule GabblerWeb.Live.Room.New do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias GabblerData.{Room, Post, User, PostMeta}
  alias GabblerData.Query.Room, as: QueryRoom


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.RoomView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.RoomView, "create.html", assigns) %>
    """
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  @doc """
  Handle a form update event where Room parameters were adjusted or the Room create/update form was submit
  """
  def handle_event("update_room", %{"_target" => ["room", "name"], "room" => %{"name" => name}}, socket) do
    {:noreply, update_room_assign(:name, name, socket)}
  end

  def handle_event("update_room", %{"_target" => ["room", "title"], "room" => %{"title" => title}}, socket) do
    {:noreply, update_room_assign(:title, title, socket)}
  end

  def handle_event("update_room", %{"_target" => ["room", "description"], "room" => %{"description" => description}}, socket) do
    {:noreply, update_room_assign(:description, description, socket)}
  end

  def handle_event("update_room", %{"_target" => ["room", "age"], "room" => %{"age" => age}}, socket) do
    {:noreply, update_room_assign(:age, age, socket)}
  end

  def handle_event("update_room", %{"_target" => ["room", "type"], "room" => %{"type" => type}}, socket) do
    {:noreply, update_room_assign(:type, type, socket)}
  end

  def handle_event("update_room", _, socket), do: {:noreply, socket}

  def handle_event("submit", _, %{assigns: %{changeset: changeset, room: room, mode: :create}} = socket) do
    case QueryRoom.create(changeset) do
      {:ok, room} ->
        {:noreply, assign(socket, room: room, changeset: Room.changeset(room), mode: :update, updated: true)}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, room: room)}
    end
  end

  def handle_event("submit", _, %{assigns: %{changeset: changeset, mode: :update}} = socket) do
    case QueryRoom.update(changeset) do
      {:ok, room} ->
        {:noreply, assign(socket, room: room, mode: :update, updated: true)}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # PRIV
  #############################
  defp init(%{"room" => name}, socket) do
    case QueryRoom.get(name) do
      nil ->
        assign(socket, default_assigns())
      room ->
        assign(socket, 
          changeset: Room.changeset(room),
          room: room, 
          status: nil, 
          room_type: "room",
          posts: Post.mock_data(),
          post_metas: PostMeta.mock_data(),
          mode: :update,
          updated: false,
          user: User.mock_data(),
          users: %{1 => User.mock_data(), 2 => User.mock_data(), 3 => User.mock_data()})
    end
  end

  defp init(_session, socket) do
    assign(socket, default_assigns())
  end

  defp update_room_assign(key, value, %{assigns: %{room: room, changeset: changeset}} = socket) do
    room = Map.put(room, key, value)

    assign(socket, 
      room: room,
      changeset: update_changeset(changeset, key, value)
    )
  end

  defp update_changeset(changeset, key, value) do
    changeset = %{changeset | :errors => Keyword.delete(changeset.errors, key)}
    |> Room.changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp default_assigns() do
    [
      changeset: Room.changeset(%Room{type: "public", age: 0, user_id_creator: 1, reputation: Application.get_env(:gabbler, :default_room_reputation, 0)}),
      room: %Room{type: "public", age: 0}, 
      status: nil, 
      room_type: "room",
      posts: Post.mock_data(),
      post_metas: PostMeta.mock_data(),
      mode: :create,
      updated: false,
      user: User.mock_data(),
      users: %{1 => User.mock_data(), 2 => User.mock_data(), 3 => User.mock_data()}
    ]
  end
end