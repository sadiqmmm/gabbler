defmodule Gabbler.User do
  @moduledoc """
  Each user has their own server storing actions in memory which helps keep timers
  on whether they can post (spam prevention) and whether they already voted on a 
  post. Also keeps their subscriptions and moderator list cached.
  """
  alias GabblerData.User
  alias Gabbler.User.Application, as: UserApp
  alias GabblerData.Query.Subscription, as: QuerySubscription
  alias GabblerData.Query.Moderating, as: QueryModerating

  # TODO: use conf
  @max_moderating 5 # Max in activity server
  @max_subscriptions 7 # Max in activity server


  def all(user) do
    call(user, :retrieve_all)
  end

  @doc """
  User voted
  """
  def activity_voted(user, post_hash) do
    call(user, :activity_voted, post_hash)
  end

  @doc """
  User posted
  """
  def activity_posted(user, post_hash) do
    call(user, :activity_posted, post_hash)
  end

  @doc """
  User subscribed to a room
  """
  def activity_subscribed(user, room_name) do
    call(user, :activity_subscribed, room_name)
  end

  def activity_unsubscribed(user, room_name) do
    call(user, :activity_unsubscribed, room_name)
  end

  @doc """
  User became moderator of a room (should be automatic if created a room)
  """
  def activity_moderating(user, room_name) do
    call(user, :activity_moderating, room_name)
  end



  @doc """
  Add a simple activity to a fixed length FILO queue. Should expect the value to be displayed
  organized by the id key
  """
  def add_activity(user, id, value) do
    call(user, :add_activity, {id, value})
  end

  @doc """
  Returns whether a user can currently post
  """
  def can_vote?(user, post_hash) do
    call(user, :can_vote, post_hash)
  end

  @doc """
  Returns whether a user can currently post
  """
  def can_post?(user) do
    call(user, :can_post)
  end

  @doc """
  Return the map of responses to users activity. Mapped post hashes to tuple with room name
  """
  def get_activity(user) do
    call(user, :get_activity)
  end

  @doc """
  Return hashes of all a users recent posts
  """
  def posts(user) do
    call(user, :get_posts)
  end

  @doc """
  Return the list of this users subscription room names
  """
  def subscriptions(user) do
    call(user, :get_subscriptions)
  end

  @doc """
  Return the map of rooms moderating, a list of moderated room names.
  """
  def moderating(user) do
    call(user, :get_moderating)
  end

  @doc """
  Create a server name based on a user so it can be found easily by id
  """
  def server_name(%User{id: id}), do: {:via, :syn, "USER_#{Integer.to_string(id)}"}

  # PRIVATE FUNCTIONS
  ###################
  defp call(user, action, args \\ [])

  defp call(nil, _, _), do: nil

  defp call(%User{} = user, action, args) when is_atom(action) do
    pid = case :syn.find_by_key(server_name(user)) do
      :undefined ->
        subs = Enum.reduce(QuerySubscription.list(user, join: :room, limit: @max_subscriptions), [], 
          fn {_, %{name: name}}, acc -> [name|acc] end)
        moderating = Enum.reduce(QueryModerating.list(user, join: :room, limit: @max_moderating), [],
          fn {_, %{name: name}}, acc -> [name|acc] end)

        case UserApp.add_child(user, subs, moderating) do
          {:error, {:already_started, pid}} -> pid
          {:ok, pid} -> pid
        end
      pid ->
        pid
    end

    case args do
      [] -> GenServer.call(pid, action)
      _  -> GenServer.call(pid, {action, args})
    end
  end
end