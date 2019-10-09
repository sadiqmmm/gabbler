defmodule Gabbler.PostCreation do
  @moduledoc """
  Helping functions for Creating a Post
  """
  alias GabblerData.Room

  @doc """
  Prepare a Post Changeset for insertion to the database
  """
  def prepare_changeset(%Room{} = room, changeset) do
    post_title = case Ecto.Changeset.fetch_field(changeset, :title) do
      {:changes, title} -> title
      {:data, title} -> title
      _ -> nil
    end

    Ecto.Changeset.change(changeset, %{hash: get_hash(post_title, room)})
  end

  @doc """
  Retrieve a unique hash representing the post. If no Post title, downstream query
  will fail anyways so can empty string.
  """
  def get_hash(nil, _), do: ""

  def get_hash(title, %Room{id: room_id}) do
    {_, _, micro} = :os.timestamp()

    Hashids.new([salt: title, min_len: 12])
    |> Hashids.encode([micro, room_id])
  end
end