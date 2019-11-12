defmodule GabblerWeb.Live.Room do
  @moduledoc """
  A set of handles for incoming events related to room functionality. Posts / Comments and room summaries all
  are in rooms.
  """
  defmacro __using__(_) do
    quote do
      import Phoenix.LiveView

      import Gabbler, only: [query: 1]
      import GabblerWeb.Gettext
      import GabblerWeb.Live.Socket, only: [no_reply: 1, update_changeset: 5]

      alias GabblerWeb.Presence

      defp init(%{room: %{name: name} = room, user: user} = session, socket) do
        if user do
          Presence.track(self(), "room:#{name}", user.id, %{name: user.name})
        end

        user_count = Presence.list("room:#{name}") |> Enum.count()

        mods =
          query(:moderating).list(room, join: :user)
          |> Enum.reduce([], fn {_, %{name: name}}, acc -> [name | acc] end)

        init(
          Map.drop(session, [:room]),
          assign(socket,
            subscribed: query(:subscription).subscribed?(user, room),
            room: room,
            room_type: "room",
            user: user,
            mod: Gabbler.User.moderating?(user, room),
            owner: query(:user).get(room.user_id_creator),
            user_count: user_count,
            moderators: mods,
            mod_invite: ""
          )
        )
      end

      @impl true
      def handle_info(
            %{event: "presence_diff", payload: _},
            %{assigns: %{room: %{name: name}}} = socket
          ) do
        user_count =
          Presence.list("room:#{name}")
          |> Enum.count()

        {:noreply, assign(socket, user_count: user_count)}
      end

      @impl true
      def handle_event("subscribe", _, %{assigns: %{user: user, room: room}} = socket) do
        case query(:subscription).subscribe(user, room) do
          {:ok, _} ->
            GabblerWeb.Endpoint.broadcast("user:#{user.id}", "subscribed", %{
              "room_name" => room.name
            })

            {:noreply, assign(socket, subscribed: true)}

          {:error, _} ->
            # TODO: handle notifying user
            {:noreply, assign(socket, subscribed: false)}
        end
      end

      def handle_event("unsubscribe", _, %{assigns: %{user: user, room: room}} = socket) do
        case query(:subscription).unsubscribe(user, room) do
          {:ok, _} ->
            GabblerWeb.Endpoint.broadcast("user:#{user.id}", "unsubscribed", %{
              "room_name" => room.name
            })

            {:noreply, assign(socket, subscribed: false)}

          {:error, _} ->
            # TODO: handle notifying user
            {:noreply, assign(socket, subscribed: true)}
        end
      end

      def handle_event(
            "submit_mod_invite",
            %{"mod" => %{"name" => user_name}},
            %{assigns: %{room: %{name: room_name}, user: %{id: user_id}}} = socket
          ) do
        case query(:user).get(user_name) do
          nil ->
            GabblerWeb.Endpoint.broadcast("user:#{user_id}", "warning", %{
              msg: gettext("User not found so mod request could not be sent")
            })

            {:noreply, socket}

          user_to_invite ->
            _ = Gabbler.User.add_activity(user_to_invite, room_name, "mod_request")

            GabblerWeb.Endpoint.broadcast("user:#{user_id}", "info", %{
              msg: gettext("Mod request sent")
            })

            {:noreply, assign(socket, mod_request: "")}
        end
      end

      def handle_event(
            "remove_mod",
            %{"name" => user_name},
            %{assigns: %{room: room, moderators: mods}} = socket
          ) do
        case query(:user).get(user_name) do
          nil ->
            {:noreply, socket}

          user ->
            _ = query(:moderating).remove_moderate(user, room)

            {:noreply,
             assign(socket, moderators: Enum.filter(mods, fn name -> name != user.name end))}
        end
      end

      # PRIVATE FUNCTIONS
      ###################
    end
  end
end
