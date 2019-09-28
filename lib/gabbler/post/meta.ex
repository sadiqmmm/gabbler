defmodule Grabbler.Post.Meta do
  @moduledoc """
  Logic related to a posts meta data: image, tags, link, comment count
  """
  @behaviour GabblerData.Behaviour.LogicMeta

  alias GabblerData.PostMeta


  @impl true
  def upload_image(_image_data, _tags), do: :ok

  @impl true
  def process_tags(%PostMeta{} = meta, tags), do: process_tags(meta, tags, [])

  @impl true
  def format_tags(tags), do: String.split(tags, ",", trim: true) |> Enum.join(", ")

  defp process_tags(_meta, [], acc), do: acc

  defp process_tags(%PostMeta{:link => link} = meta, ["youtube"|t], acc) do
    url = URI.parse(link)
    |> Map.get(:query)
    |> URI.decode_query()

    html = Phoenix.View.render_to_string(GabblerWeb.EmbedView, "youtube.html", %{:hash => url["v"]})

    process_tags(meta, t, [{:html, html}|acc])
  end

  defp process_tags(%PostMeta{:link => link} = meta, ["bingmap"|t], acc) do
    url = URI.parse(link)
    |> Map.get(:query)
    |> URI.decode_query()

    cond do
      url["cp"] ->
        html = Phoenix.View.render_to_string(GabblerWeb.EmbedView, "bing_map.html", %{
          :coord => url["cp"], 
          :position => String.replace(url["cp"], "~", "_")})
        
        process_tags(meta, t, [{:html, html}|acc])
      true ->
        process_tags(meta, t, acc)
    end
  end
end