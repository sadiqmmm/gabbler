defmodule GabblerWeb.Live.TagTracker.Index do
  @moduledoc """
  The tag tracking special room
  """
  use GabblerWeb.Live.Voting
  use Phoenix.LiveView
  import Gabbler, only: [query: 1]
  import GabblerWeb.Gettext

  alias Gabbler.TagTracker
  alias GabblerData.User

  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PageView, "tag_tracker.html", assigns) %>
    """
  end

  def handle_info(
        %{event: "tag_list", payload: %{list: posts}},
        %{assigns: %{posts: curr_posts} = assigns} = socket
      ) do
    {:noreply,
     assign(socket,
       posts: Enum.uniq(posts ++ curr_posts),
       post_metas: Map.merge(query(:post).map_meta(posts), assigns.post_metas),
       users: Map.merge(query(:post).map_users(posts), assigns.users),
       rooms: Map.merge(query(:post).map_rooms(posts), assigns.rooms)
     )}
  end

  def handle_event(
        "submit",
        %{"tag" => %{"tracker" => tag}},
        %{assigns: %{tag_channel: channel}} = socket
      ) do
    GabblerWeb.Endpoint.unsubscribe(channel)

    tag_channel = TagTracker.tag_channel(tag)

    GabblerWeb.Endpoint.subscribe(tag_channel)

    _ = TagTracker.get(tag, tag_channel)

    {:noreply, assign(socket, posts: [], tag_channel: tag_channel, current_tag: tag)}
  end

  def mount(session, socket) do
    {channel, _user} =
      case session do
        %{user: %User{id: id} = user} -> {TagTracker.user_channel(id), user}
        %{temp_token: token} -> {TagTracker.user_channel(token), token}
      end

    GabblerWeb.Endpoint.subscribe(channel)

    _ = TagTracker.get(:trending, channel)

    {:ok,
     assign(socket,
       tag_channel: channel,
       current_tag: gettext("all trending"),
       posts: [],
       post_metas: %{},
       users: %{},
       rooms: %{}
     )}
  end

  # PRIV
  #############################
end
