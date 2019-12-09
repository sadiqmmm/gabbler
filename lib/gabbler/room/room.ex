defmodule Gabbler.Room do
  @moduledoc """
  Each room has it's own server responsible for decaying it's posts and deactivating if the room loses activity
  for long enough.
  """

  def server_name(room_name) when is_binary(room_name), do: {:via, :syn, "ROOM_#{Integer.to_string(room_name)}"}
end