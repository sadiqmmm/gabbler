defmodule Gabbler.Guards do
  defguard query_module?(module) when module in [:Post, :Room, :User, :Moderating, :Subscription]
end