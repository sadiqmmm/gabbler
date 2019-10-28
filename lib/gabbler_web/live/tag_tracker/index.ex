defmodule GabblerWeb.Live.TagTracker.Index do
  @moduledoc """
  The tag tracking special room
  """
  use GabblerWeb.Live.Voting
  use Phoenix.LiveView
  import GabblerWeb.Gettext

  alias Gabbler.TagTracker
  alias GabblerData.User
  alias GabblerData.Query.Post, as: QueryPost


  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PageView, "tag_tracker.html", assigns) %>
    """
  end

  def handle_info(%{event: "tag_list", payload: %{list: posts}}, %{assigns: %{posts: curr_posts} = assigns} = socket) do
    {:noreply, assign(socket, 
      posts: Enum.uniq(posts ++ curr_posts),
      post_metas: Map.merge(QueryPost.map_meta(posts), assigns.post_metas),
      users: Map.merge(QueryPost.map_users(posts), assigns.users),
      rooms: Map.merge(QueryPost.map_rooms(posts), assigns.rooms))}
  end

  def handle_event("submit", %{"tag" => %{"tracker" => tag}}, %{assigns: %{tag_channel: channel}} = socket) do
    GabblerWeb.Endpoint.unsubscribe(channel)

    tag_channel = TagTracker.tag_channel(tag)

    GabblerWeb.Endpoint.subscribe(tag_channel)

    _ = TagTracker.get(tag, tag_channel)

    {:noreply, assign(socket, posts: [], tag_channel: tag_channel, current_tag: tag)}
  end

  def mount(session, socket) do
    {channel, _user} = case session do
      %{user: %User{id: id} = user} -> {TagTracker.user_channel(id), user}
      %{temp_token: token} -> {TagTracker.user_channel(token), token}
    end

    GabblerWeb.Endpoint.subscribe(channel)

    _ = TagTracker.get(:trending, channel)

    {:ok, assign(socket,
      tag_channel: channel,
      current_tag: gettext("all trending"),
      posts: [],
      post_metas: %{},
      users: %{},
      rooms: %{})}
  end

  # PRIV
  #############################
  defp map_to_posts(tracked_posts), do: map_to_posts(tracked_posts, [])

  defp map_to_posts([], acc), do: acc

  defp map_to_posts([{_, post_id}|t], acc) do
    case QueryPost.get(post_id) do
      nil  -> map_to_posts(t, acc)
      post -> map_to_posts(t, [post|acc])
    end
  end
end