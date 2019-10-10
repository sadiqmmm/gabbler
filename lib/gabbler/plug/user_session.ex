defmodule Gabbler.Plug.UserSession do
  @moduledoc """
  Puts the current user in the connection object for client consumption
  """
  import Plug.Conn

  alias Gabbler.Auth.Guardian


  def init(_), do: :ok

  def call(conn, _default) do
    user = Guardian.Plug.current_resource(conn)

    case user do
      nil ->
        {conn, token} = Guardian.gen_temp_token(conn)

        assign(conn, :user, nil)
        |> assign(:temp_token, token)
      user -> 
        assign(conn, :user, user)
    end
  end
end