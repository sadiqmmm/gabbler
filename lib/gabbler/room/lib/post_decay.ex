defmodule Gabbler.Room.PostDecay do
  @moduledoc """
  This module provides some abstraction to decay a posts relevance by time
  """
  alias GabblerData.Post
  alias Gabbler.Room.RoomState

  @decay_by 10

  @doc """
  Get the atom version of an expirey mode
  """
  def decay("rapid"), do: :rapid
  def decay("slow"), do: :slow
  def decay("never"), do: :never

  @doc """
  Get the amount of time until decay (milliseconds)
  """
  def set_decay_timer(:rapid) do
    # 1 hour
    Process.send_after(self(), :decay, 3600000)
    :ok
  end

  def set_decay_timer(:slow) do
    # 4 hours
    Process.send_after(self(), :decay, 144000000)
    :ok
  end

  def set_decay_timer(_), do: nil

  @doc """
  Decay a post
  """
  def decay_post(%Post{score_private: _}, %RoomState{}) do
    :ok
  end
end