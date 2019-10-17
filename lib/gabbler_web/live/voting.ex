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
      import GabblerWeb.Gettext
      alias GabblerData.Query.Post, as: QueryPost

      # Post is set, voting on Post page on OP
      def handle_event("vote",
      %{"hash" => vote_hash, "dir" => dir}, 
      %{assigns: %{post: %{hash: hash} = post, op: %{hash: op_hash}, room: %{name: room_name}, user: user}} = socket) when vote_hash == hash do
        case vote(user, post, dir) do
          {:ok, post} ->
            {:noreply, assign(socket, post: broadcast_vote(post, op_hash, room_name))}
          {:error, error_str} ->
            GabblerWeb.Endpoint.broadcast("user:#{user.id}", "warning", %{msg: error_str})
            {:noreply, socket}
        end
      end

      # Posts is set, voting from Room summary page
      def handle_event("vote",
      %{"hash" => vote_hash, "dir" => dir}, 
      %{assigns: %{posts: posts, room: %{name: room_name}, user: user}} = socket) do
        posts = Enum.map(posts, fn %{hash: hash} = post ->
          if hash == vote_hash do
            # OP is definitely post if from a room
            case vote(user, post, dir) do
              {:ok, post} ->
                broadcast_vote(post, post.hash, room_name)
              {:error, error_str} ->
                GabblerWeb.Endpoint.broadcast("user:#{user.id}", "warning", %{msg: error_str})
                post
            end
          else
            post
          end
        end)
        
        {:noreply, assign(socket, posts: posts)}
      end

      # Comments is set and prev clause no match so we are voting on a post page but not the OP
      def handle_event("vote",
      %{"hash" => vote_hash, "dir" => dir},
      %{assigns: %{comments: comments, op: %{hash: op_hash}, room: %{name: room_name}, user: user}} = socket) do
        comments = Enum.map(comments, fn %{hash: hash} = comment ->
          if hash == vote_hash do
            case vote(user, comment, dir) do
              {:ok, comment} ->
                broadcast_vote(comment, op_hash, room_name)
              {:error, error_str} ->
                GabblerWeb.Endpoint.broadcast("user:#{user.id}", "warning", %{msg: error_str})
                comment
            end
          else
            comment
          end
        end)
        
        {:noreply, assign(socket, comments: comments)}
      end

      def handle_event("vote", _, socket), do: {:noreply, socket}

      def handle_info(%{event: "new_vote", payload: %{post: %{hash: voted_hash} = post}}, 
      %{assigns: %{posts: posts}} = socket) do
        case Enum.find_index(posts, fn %{hash: hash} -> voted_hash == hash end) do
          nil -> {:noreply, socket}
          i -> {:noreply, assign(socket, posts: List.replace_at(posts, i, post))}
        end
      end

      def handle_info(%{event: "new_vote", payload: %{post: %{hash: voted_hash} = post}}, 
      %{assigns: %{post: %{hash: hash}}} = socket) when hash == voted_hash do
        {:noreply, assign(socket, post: post)}
      end

      def handle_info(%{event: "new_vote", payload: %{post: %{hash: voted_hash} = post}}, 
      %{assigns: %{comments: comments}} = socket) do
        case Enum.find_index(comments, fn %{hash: hash} -> voted_hash == hash end) do
          nil -> {:noreply, socket}
          i -> {:noreply, assign(socket, comments: List.replace_at(comments, i, post))}
        end
      end

      # PRIVATE FUNCTIONS
      ###################
      defp vote(user, post, "up") do
        vote(user, post, 1)
      end

      defp vote(user, post, "down") do
        vote(user, post, -1)
      end

      defp vote(user, %{hash: hash} = post, amt) do
        if Gabbler.User.can_vote?(user, hash) do
          case QueryPost.increment_score(post, amt, nil) do
            {1, nil} -> 
              Gabbler.User.activity_voted(user, hash)

              {:ok, %{post | :score_public => post.score_public + amt}}
            _ -> 
              {:error, dgettext("errors", "there was an issue voting")}
          end
        else
          {:error, dgettext("errors", "you have reached your voting capacity for today or already voted here")}
        end
      end

      def broadcast_vote(post, op_hash, room_name) do
        GabblerWeb.Endpoint.broadcast("post_live:#{op_hash}", "new_vote", %{post: post})
        GabblerWeb.Endpoint.broadcast("room_live:#{room_name}", "new_vote", %{post: post})

        post
      end
    end
  end
end