defmodule Pictionary.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PictionaryWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pictionary, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pictionary.PubSub},
      # Start the registry for tracking running games. It uses Horde: Elixir library that provides a distributed and supervised process registry.
      {Horde.Registry, [name: Pictionary.GameRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor, [name: Pictionary.DistributedSupervisor, strategy: :one_for_one, members: :auto]},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Pictionary.Finch},
      # Start a worker by calling: Pictionary.Worker.start_link(arg)
      # {Pictionary.Worker, arg},
      # Start to serve requests, typically the last entry
      PictionaryWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pictionary.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PictionaryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
