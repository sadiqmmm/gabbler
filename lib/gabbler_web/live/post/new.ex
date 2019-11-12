defmodule GabblerWeb.Live.Post.New do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView
  import Gabbler, only: [query: 1]
  import GabblerWeb.Live.Socket, only: [no_reply: 1]

  alias Gabbler.PostCreation
  alias GabblerData.{Post, PostMeta}

  def render(assigns) do
    ~L"""
      <%= Phoenix.View.render(GabblerWeb.PostView, "index.html", assigns) %>

      <%= Phoenix.View.render(GabblerWeb.PostView, "create.html", assigns) %>
    """
  end

  @doc """
  Set default form and status of creation
  """
  def mount(session, socket) do
    {:ok, init(session, socket)}
  end

  @doc """
  Handle a form update event where Post parameters were adjusted or the Post create/update form was submit
  """
  def handle_event(
        "update_post",
        %{"_target" => ["post", "title"], "post" => %{"title" => title}},
        socket
      ) do
    update_post_assign(socket, :title, title)
    |> no_reply()
  end

  def handle_event(
        "update_post",
        %{"_target" => ["post", "body"], "post" => %{"body" => body}},
        socket
      ) do
    update_post_assign(socket, :body, body)
    |> no_reply()
  end

  def handle_event(
        "update_post",
        %{"_target" => ["post_meta", "link"], "post_meta" => %{"link" => link}},
        socket
      ) do
    update_post_meta_assign(socket, :link, link)
    |> no_reply()
  end

  def handle_event(
        "update_post",
        %{"_target" => ["post_meta", "image"], "post_meta" => %{"image" => image}},
        socket
      ) do
    assign(socket, upload: image)
    |> no_reply()
  end

  def handle_event(
        "update_post",
        %{"_target" => ["post_meta", "tags"], "post_meta" => %{"tags" => tags}},
        socket
      ) do
    update_post_meta_assign(socket, :tags, tags)
    |> no_reply()
  end

  def handle_event("update_post", _, socket), do: {:noreply, socket}

  # TODO: too much logic.. belongs in Gabbler namespace
  def handle_event(
        "submit",
        _,
        %{
          assigns: %{
            mode: :create,
            room: %{name: room_name} = room,
            user: user,
            changeset: changeset,
            changeset_meta: changeset_meta,
            updated: updated
          }
        } = socket
      ) do
    case PostCreation.create(user, room, changeset, changeset_meta) do
      {:ok, {%{hash: hash} = post, meta}} ->
        _users_posts = Gabbler.User.activity_posted(user, hash)

        _ = Gabbler.TagTracker.add_tags(post, meta)

        GabblerWeb.Endpoint.broadcast("room_live:#{room_name}", "new_post", %{
          :post => post,
          :meta => meta
        })

        GabblerWeb.Endpoint.broadcast("user:#{user.id}", "new_post", %{
          :post => post,
          :meta => meta
        })

        assign(socket,
          post: post,
          post_meta: meta,
          changeset: Post.changeset(post),
          changeset_meta: PostMeta.changeset(meta),
          mode: :update,
          updated: update_updated(updated)
        )

      {:error, {:post, changeset}} ->
        assign(socket, changeset: changeset)

      {:error, {:post_meta, changeset}} ->
        assign(socket, changeset_meta: changeset)

      {:error, error_str} ->
        GabblerWeb.Endpoint.broadcast("user:#{user.id}", "warning", %{msg: error_str})

        socket
    end
    |> no_reply()
  end

  def handle_event(
        "submit",
        _,
        %{
          assigns: %{
            mode: :update,
            changeset: changeset,
            changeset_meta: changeset_meta,
            updated: updated
          }
        } = socket
      ) do
    update_set =
      case query(:post).update(changeset) do
        {:ok, post} ->
          [post: post, changeset: Post.changeset(post), mode: :update, updated: true]

        {:error, changeset} ->
          [changeset: changeset]
      end

    update_meta_set =
      case query(:post).update_meta(changeset_meta) do
        {:ok, post_meta} ->
          [
            post_meta: post_meta,
            changeset_meta: PostMeta.changeset(post_meta),
            updated: true,
            updated: update_updated(updated)
          ]

        {:error, changeset} ->
          [changeset_meta: changeset]
      end

    assign(socket, Keyword.merge(update_set, update_meta_set))
    |> no_reply()
  end

  def handle_event("submit", _, %{assigns: %{mode: :create}} = socket) do
    {:noreply, socket}
  end

  def handle_event("reply", _, socket) do
    {:noreply, socket}
  end

  # PRIV
  #############################
  defp init(%{room: %{id: room_id} = room, user: %{id: user_id} = user}, socket) do
    assign(socket,
      changeset:
        Post.changeset(%Post{user_id_post: user_id, parent_id: room_id, parent_type: "room"}),
      changeset_meta: PostMeta.changeset(%PostMeta{user_id: user_id}),
      post: %Post{user_id_post: user_id},
      body: "",
      post_meta: %PostMeta{user_id: user_id},
      changeset_reply: nil,
      page: 1,
      pages: 1,
      comments: [],
      upload: nil,
      parent: nil,
      uploads: Application.get_env(:gabbler, :uploads, :off),
      room: room,
      room_type: "room",
      mode: :create,
      updated: false,
      user: user,
      post_user: user,
      mod: false
    )
  end

  defp update_post_assign(%{assigns: %{post: post, changeset: changeset}} = socket, :body, value) do
    sanitized_value = HtmlSanitizeEx.strip_tags(value)

    post = Map.put(post, :body, sanitized_value)

    assign(socket,
      post: post,
      body: value,
      changeset: update_changeset(changeset, :body, sanitized_value)
    )
  end

  defp update_post_assign(%{assigns: %{post: post, changeset: changeset}} = socket, key, value) do
    post = Map.put(post, key, value)

    assign(socket,
      post: post,
      changeset: update_changeset(changeset, key, value)
    )
  end

  defp update_post_meta_assign(
         %{assigns: %{post_meta: post_meta, changeset_meta: changeset}} = socket,
         key,
         value
       ) do
    post_meta = Map.put(post_meta, key, value)

    assign(socket,
      post_meta: post_meta,
      changeset_meta: update_changeset_meta(changeset, key, value)
    )
  end

  defp update_changeset(changeset, key, value) do
    changeset =
      %{changeset | :errors => Keyword.delete(changeset.errors, key)}
      |> Post.changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp update_changeset_meta(changeset, key, value) do
    changeset =
      %{changeset | :errors => Keyword.delete(changeset.errors, key)}
      |> PostMeta.changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp update_updated(false), do: 1
  defp update_updated(updated), do: updated + 1
end
