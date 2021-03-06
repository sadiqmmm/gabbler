defmodule GabblerWeb.Live.Voting do
  @moduledoc """
  A set of voting handles that any liveview making use of voting can utilize. Expects the socket
  to contain a post or comments. If not found, socket will be replied unaltered. An event is also
  broadcast for those listening in on a room channel.
  Dir refers to direction
  """
  defmacro __using__(_) do
    quote do
      import Phoenix.LiveView
      import Gabbler, only: [query: 1]
      import GabblerWeb.Gettext
      import Gabbler.Live.SocketUtil, only: [no_reply: 1]
      
      alias GabblerData.Post


      @doc """
      The current user votes
      """
      def handle_event("vote", %{"hash" => hash, "dir" => dir}, %{assigns: assigns} = socket) do
        get_vote_post(assigns, hash)
        |> vote(assigns, dir)
        |> assign_vote(socket)
        |> broadcast_vote()
        |> no_reply()
      end

      @doc """
      A new vote event happens on the current room or post subscription
      (someone else voted on the currently viewed topic)
      """
      def handle_info(%{event: "new_vote", payload: %{post: %{hash: hash} = post}}, %{assigns: assigns} = socket) do
        get_vote_post(assigns, hash)
        |> assign_vote(socket)
        |> get_socket()
        |> no_reply()
      end

      # PRIVATE FUNCTIONS
      ###################
      defp get_vote_post(%{op: %{hash: op_hash} = op}, hash) when op_hash == hash, do: op
      
      defp get_vote_post(%{comments: comments, op: _}, hash) do
        Enum.filter(comments, fn %{hash: comment_hash} -> comment_hash == hash end)
        |> List.first()
      end
      
      defp get_vote_post(%{posts: posts}, hash) do
        Enum.filter(posts, fn %{hash: post_hash} -> post_hash == hash end)
        |> List.first()
      end
      
      defp get_vote_post(_, _), do: nil

      defp vote(nil, _, _), do: nil
      defp vote(post, %{user: user} = assigns, "up"), do: vote(post, user, 1)
      defp vote(post, %{user: user} = assigns, "down"), do: vote(post, user, -1)

      defp vote(%{hash: hash} = post, user, amt) do
        if Gabbler.User.can_vote?(user, hash) do
          case query(:post).increment_score(post, amt, nil) do
            {1, nil} ->
              Gabbler.User.activity_voted(user, hash)

              {:ok, %{post | :score_public => post.score_public + amt}}

            _ ->
              {:error, dgettext("errors", "there was an issue voting")}
          end
        else
          {:error,
           dgettext(
             "errors",
             "you have reached your voting capacity for today or already voted here"
           )}
        end
      end

      defp assign_vote({:ok, post}, %{assigns: %{comments: comments, room: room}} = socket) do
        comments = replace_post(comments, post)

        {:ok, post, assign(socket, comments: comments)}
      end

      defp assign_vote({:ok, post}, %{assigns: %{posts: posts, room: room}} = socket) do
        posts = replace_post(posts, post)

        {:ok, post, assign(socket, posts: posts)}
      end

      defp assign_vote({:ok, post}, %{assigns: %{posts: posts, rooms: rooms}} = socket) do
        posts = replace_post(posts, post)

        {:ok, post, assign(socket, posts: posts)}
      end

      defp assign_vote({:ok, post}, %{assigns: %{room: room}} = socket) do
        {:ok, post, assign(socket, post: post)}
      end

      defp assign_vote({:error, error_str}, socket) do
        {:error, error_str, socket}
      end

      defp assign_vote(%Post{} = post, socket), do: assign_vote({:ok, post}, socket)

      defp assign_vote(nil, socket), do: {:noop, nil, socket}

      # TODO: moving some of this to a broadcasting protocol?
      defp broadcast_vote({:ok, post, %{assigns: %{room: %{name: room_name}}} = socket}) do
        GabblerWeb.Endpoint.broadcast("post_live:#{post.hash}", "new_vote", %{post: post})
        GabblerWeb.Endpoint.broadcast("room_live:#{room_name}", "new_vote", %{post: post})

        socket
      end

      defp broadcast_vote({:ok, %{id: post_id, hash: hash} = post, %{assigns: %{rooms: rooms}} = socket}) do
        GabblerWeb.Endpoint.broadcast("post_live:#{hash}", "new_vote", %{post: post})

        if room = Map.get(rooms, post_id) do
          GabblerWeb.Endpoint.broadcast("room_live:#{room.name}", "new_vote", %{post: post})
        end

        socket
      end

      defp broadcast_vote({:error, error_str, %{assigns: %{user: %{id: user_id}}} = socket}) do
        GabblerWeb.Endpoint.broadcast("user:#{user_id}", "warning", %{msg: error_str})

        socket
      end

      defp broadcast_vote({:noop, nil, socket}), do: socket

      defp get_socket({_, _, socket}), do: socket

      defp replace_post(posts, post) do
        Enum.map(posts, fn %{hash: hash} = current_post ->
          cond do
            hash == post.hash -> post
            true -> current_post
          end
        end)
      end
    end
  end
end
