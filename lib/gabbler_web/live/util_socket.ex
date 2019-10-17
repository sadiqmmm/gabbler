defmodule GabblerWeb.Live.UtilSocket do
  @moduledoc """
  All functions here should accept a socket and return a socket. Meant for common functionality related
  to forms and liveviews. This module is best used via import
  """
  import Phoenix.LiveView

  alias GabblerData.{Room, Post, PostMeta, Comment, User}


  def update_assign(changeset_name, type, key, value, %{assigns: assigns} = socket) do
    changeset      = Map.get(assigns, changeset_name)
    value_update   = Map.get(assigns, type)
    updated_struct = Map.put(value_update, key, value)

    assign(socket, [{type, updated_struct}, {changeset_name, update_changeset(changeset, type, key, value)}])
  end

  def update_changeset(changeset, type, key, value) do
    changeset = %{changeset | :errors => Keyword.delete(changeset.errors, key)}
    |> changeset_model(type).changeset(%{key => value})

    case changeset do
      %{:errors => []} -> %{changeset | :valid? => true}
      _ -> changeset
    end
  end

  defp changeset_model(:comment), do: Comment
  defp changeset_model(:reply), do: Comment
  defp changeset_model(:room), do: Room
  defp changeset_model(:post), do: Post
  defp changeset_model(:post_meta), do: PostMeta
  defp changeset_model(:user), do: User
end