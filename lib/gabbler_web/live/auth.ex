defmodule GabblerWeb.Live.Auth do
  @moduledoc """
  Functions that handle events related to auth such as requiring login for events from the UI
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Phoenix.LiveView

      @auth_req Keyword.fetch!(opts, :auth_required)

      # Authorization required events as defined by the Module using Live.Auth
      def handle_event(event, _, %{assigns: %{user: nil, temp_token: token}} = socket)
          when event in @auth_req do
        GabblerWeb.Endpoint.broadcast("user:#{token}", "login_show", %{})

        {:noreply, socket}
      end

      # PRIVATE FUNCTIONS
      ###################
      # Takes the temp token off the top, adds to the socket and disqualifies mount from matching here again
      defp init(%{temp_token: token} = session, socket) do
        init(Map.delete(session, :temp_token), assign(socket, temp_token: token, user: nil))
      end
    end
  end
end
