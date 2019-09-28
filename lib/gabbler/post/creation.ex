defmodule Gabbler.PostCreation do
  @moduledoc """
  Helping functions for Creating a Post
  """
  alias GabblerData.{Post, Room}

  @doc """
  Prepare a Post Changeset for insertion to the database
  """
  def prepare_changeset(%Room{} = room, %{changes: post} = changeset) do
    Post.changeset(changeset, %{:hash => get_hash(post, room)})
  end

  @doc """
  Retrieve a unique hash representing the post. If no Post title, downstream query
  will fail anyways so can empty string.
  """
  def get_hash(%{title: nil}, _), do: ""

  def get_hash(%{title: title}, %Room{id: room_id}) do
    {_, _, micro} = :os.timestamp()

    Hashids.new([salt: title, min_len: 12])
    |> Hashids.encode([micro, room_id])
  end
end