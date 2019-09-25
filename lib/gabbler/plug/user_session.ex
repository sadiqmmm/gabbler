defmodule Gabbler.Plug.UserSession do
  @moduledoc """
  Puts the current user in the connection object for client consumption
  """
  import Plug.Conn

  alias GabblerData.User


  def init(_), do: :ok

  def call(conn, _default) do
    #user = Guardian.Plug.current_resource(conn)

    #claims = Guardian.Plug.current_claims(conn)

    assign(conn, :user, User.mock_data())
  end
end