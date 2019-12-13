defmodule Gabbler.Room do
  @moduledoc """
  Each room has it's own server responsible for decaying it's posts and deactivating if the room loses activity
  for long enough.
  """
  import Gabbler, only: [query: 1]

  alias Gabbler.Room.Application, as: RoomApp
  alias Gabbler.Room.RoomState


  @doc """
  Retrieve the room from state
  """
  def get_room(room_name), do: call(room_name, :get_room)

  @doc """
  Get identifying process id for a room
  """
  def server_name(room_name) when is_binary(room_name), do: {:via, :syn, "ROOM_#{room_name}"}

  # PRIVATE FUNCTIONS
  ###################
  defp call(room_name, action, args \\ nil) do
    pid = get_room_server_pid(room_name)

    case args do
      nil -> GenServer.call(pid, action)
      _ -> GenServer.call(pid, {action, args})
    end
  end

  defp get_room_server_pid(room_name) do
    case :syn.find_by_key(server_name(room_name)) do
      :undefined ->
        case query(:room).get(room_name) do
          nil -> 
            nil
          room -> 
            case RoomApp.add_child(%RoomState{room: room}) do
              {:error, {:already_started, pid}} -> pid
              {:ok, pid} -> pid
            end
        end

      pid ->
        pid
    end
  end
end