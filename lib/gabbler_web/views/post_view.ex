defmodule GabblerWeb.PostView do
  use GabblerWeb, :view

  def posted_at(nil), do: "at unknown time"
  
  def posted_at(datetime) do
    Timex.format!(datetime, "{relative}", :relative)
  end

  def show_error(nil), do: ""
  def show_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end