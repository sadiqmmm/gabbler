defmodule GabblerWeb.Live.Post.New do
  @moduledoc """
  The Room Creation LiveView form
  """
  use Phoenix.LiveView

  alias Gabbler.PostCreation
  alias GabblerData.{Post, PostMeta}
  alias GabblerData.Query.Post, as: QueryPost


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
  def handle_event("update_post", %{"_target" => ["post", "title"], "post" => %{"title" => title}}, socket) do
    {:noreply, update_post_assign(:title, title, socket)}
  end

  def handle_event("update_post", %{"_target" => ["post", "body"], "post" => %{"body" => body}}, socket) do
    {:noreply, update_post_assign(:body, body, socket)}
  end

  def handle_event("update_post", %{"_target" => ["post_meta", "link"], "post_meta" => %{"link" => link}}, socket) do
    {:noreply, update_post_meta_assign(:link, link, socket)}
  end

  def handle_event("update_post", %{"_target" => ["post_meta", "image"], "post_meta" => %{"image" => image}}, socket) do
    {:noreply, assign(socket, upload: image)}
  end

  def handle_event("update_post", %{"_target" => ["post_meta", "tags"], "post_meta" => %{"tags" => tags}}, socket) do
    {:noreply, update_post_meta_assign(:tags, tags, socket)}
  end

  def handle_event("update_post", _, socket), do: {:noreply, socket}

  def handle_event("submit", _, %{
    assigns: %{mode: :create, room: %{name: room_name} = room, user: user,
    changeset: changeset, changeset_meta: changeset_meta, updated: updated,
  }} = socket) do
    case PostCreation.create(user, room, changeset, changeset_meta) do
      {:ok, {%{hash: hash} = post, meta}} ->
        _users_posts = Gabbler.User.activity_posted(user, hash)

        _ = Gabbler.TagTracker.add_tags(post, meta)

        GabblerWeb.Endpoint.broadcast("room_live:#{room_name}", "new_post", %{:post => post, :meta => meta})

        {:noreply, assign(socket, 
          post: post,
          post_meta: meta,
          changeset: Post.changeset(post),
          changeset_meta: PostMeta.changeset(meta),
          mode: :update,
          updated: update_updated(updated))}
      {:error, {:post, changeset}} ->
        {:noreply, assign(socket, changeset: changeset)}
      {:error, {:post_meta, changeset}} ->
        {:noreply, assign(socket, changeset_meta: changeset)}
      {:error, error_str} ->
        GabblerWeb.Endpoint.broadcast("user:#{user.id}", "warning", %{msg: error_str})

        {:noreply, socket}
    end
  end

  def handle_event("submit", _, %{assigns: %{
    mode: :update, changeset: changeset, changeset_meta: changeset_meta, updated: updated
  }} = socket) do
    update_set = case QueryPost.update(changeset) do
      {:ok, post} ->
        [post: post, changeset: Post.changeset(post), mode: :update, updated: true]
      {:error, changeset} ->
        [changeset: changeset]
    end

    update_meta_set = case QueryPost.update_meta(changeset_meta) do
      {:ok, post_meta} ->
        [post_meta: post_meta, changeset_meta: PostMeta.changeset(post_meta), updated: true, updated: update_updated(updated)]
      {:error, changeset} ->
        [changeset_meta: changeset]
    end
    
    {:noreply, assign(socket, Keyword.merge(update_set, update_meta_set))}
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
      changeset: Post.changeset(%Post{user_id_post: user_id, parent_id: room_id, parent_type: "room"}),
      changeset_meta: PostMeta.changeset(%PostMeta{user_id: user_id}),
      post: %Post{user_id_post: user_id},
      body: "",
      post_meta: %PostMeta{user_id: user_id},
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
      mod: false)
  end

  defp update_post_assign(:body, value, %{assigns: %{post: post, changeset: changeset}} = socket) do
    sanitized_value = HtmlSanitizeEx.strip_tags(value)

    post = Map.put(post, :body, sanitized_value)

    assign(socket, 
      post: post,
      body: value,
      changeset: update_changeset(changeset, :body, sanitized_value)
    )
  end

  defp update_post_assign(key, value, %{assigns: %{post: post, changeset: changeset}} = socket) do
    post = Map.put(post, key, value)

    assign(socket, 
      post: post,
      changeset: update_changeset(changeset, key, value)
    )
  end

  defp update_post_meta_assign(key, value, %{assigns: %{post_meta: post_meta, changeset_meta: changeset}} = socket) do
    post_meta = Map.put(post_meta, key, value)

    assign(socket, 
      post_meta: post_meta,
      changeset_meta: update_changeset_meta(changeset, key, value)
    )
  end

  defp update_changeset(changeset, key, value) do
    changeset = %{changeset | :errors => Keyword.delete(changeset.errors, key)}
    |> Post.changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp update_changeset_meta(changeset, key, value) do
    changeset = %{changeset | :errors => Keyword.delete(changeset.errors, key)}
    |> PostMeta.changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp update_updated(false), do: 1
  defp update_updated(updated), do: updated + 1
end