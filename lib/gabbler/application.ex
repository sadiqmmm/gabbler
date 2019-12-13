defmodule Gabbler.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Initialize syn, global process registry
    :syn.start()
    :syn.init()

    children = [
      GabblerData.Repo,
      GabblerWeb.Endpoint,
      GabblerWeb.Presence,
      {Gabbler.User.Application, strategy: :one_for_one, name: :user_server},
      {Gabbler.Room.Application, strategy: :one_for_one, name: :room_server},
      Gabbler.TagTracker.Application,
      worker(Gabbler.Scheduler, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Gabbler.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GabblerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
