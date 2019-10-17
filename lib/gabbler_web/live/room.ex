defmodule GabblerWeb.Live.Room do
  @moduledoc """
  A set of handles for incoming events related to room functionality. Posts / Comments and room summaries all
  are in rooms.
  """
  defmacro __using__(_) do
    quote do
      import Phoenix.LiveView

      alias GabblerWeb.Presence
      alias GabblerData.Query.Subscription, as: QuerySubscription


      def mount(%{room: %{name: name} = room, user: user} = session, socket) do
        if user do
          Presence.track(self(), "room:#{name}", user.id, %{name: user.name})
        end

        user_count = Presence.list("room:#{name}") |> Enum.count()

        {:ok, init(session, assign(socket,
          subscribed: QuerySubscription.subscribed?(user, room),
          room: room,
          room_type: "room",
          user: user,
          mod: false,
          user_count: user_count
        ))}
      end

      @impl true
      def handle_info(%{event: "presence_diff", payload: _}, %{assigns: %{room: %{name: name}}} = socket) do
        user_count = Presence.list("room:#{name}")
        |> Enum.count()

        {:noreply, assign(socket, user_count: user_count)}
      end

      @impl true
      def handle_event("subscribe", _, %{assigns: %{user: user, room: room}} = socket) do
        case QuerySubscription.subscribe(user, room) do
          {:ok, _} ->
            GabblerWeb.Endpoint.broadcast("user:#{user.id}", "subscribed", %{"room_name" => room.name})

            {:noreply, assign(socket, subscribed: true)}
          {:error, _} ->
            # TODO: handle notifying user
            {:noreply, assign(socket, subscribed: false)}
        end
      end

      def handle_event("unsubscribe", _, %{assigns: %{user: user, room: room}} = socket) do
        case QuerySubscription.unsubscribe(user, room) do
          {:ok, _} ->
            GabblerWeb.Endpoint.broadcast("user:#{user.id}", "unsubscribed", %{"room_name" => room.name})

            {:noreply, assign(socket, subscribed: false)}
          {:error, _} ->
            # TODO: handle notifying user
            {:noreply, assign(socket, subscribed: true)}
        end
      end

      # PRIVATE FUNCTIONS
      ###################
    end
  end
end