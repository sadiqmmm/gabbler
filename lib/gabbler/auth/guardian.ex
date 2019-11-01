defmodule Gabbler.Auth.Guardian do
  use Guardian, otp_app: :gabbler
  # use Guardian.Permissions.Bitwise

  alias GabblerData.Query.User, as: QueryUser

  def subject_for_token(%{id: user_id}, _claims) do
    {:ok, to_string(user_id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case QueryUser.get(String.to_integer(id)) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def gen_temp_token(%{remote_ip: {num1, num2, num3, num4}} = conn) do
    {_, _, micro} = :os.timestamp()

    case Plug.Conn.get_session(conn, :temp_token) do
      nil ->
        token =
          Hashids.new(salt: "gabbler_temp_token", min_len: 16)
          |> Hashids.encode([micro, num1, num2, num3, num4])

        _ = Plug.Conn.put_session(conn, :temp_token, token)

        {conn, token}

      token ->
        {conn, token}
    end
  end

  def gen_temp_token(conn), do: conn

  # def build_claims(claims, _resource, opts) do
  #  claims = claims
  #  |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
  #  {:ok, claims}
  # end
end
