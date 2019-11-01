defmodule GabblerWeb.UserView do
  use GabblerWeb, :view

  def get_activity_subjects(posts, rooms, post_id, "reply") do
    Enum.reduce(posts, {nil, nil}, fn %{id: id} = post, acc ->
      if id == post_id do
        {post, rooms[post_id]}
      else
        acc
      end
    end)
  end
end