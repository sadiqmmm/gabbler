defmodule Gabbler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      GabblerData.Repo,
      GabblerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Gabbler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GabblerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
