defmodule HTTPlex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HTTPlexWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:httplex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HTTPlex.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: HTTPlex.Finch},
      # Start a worker by calling: HTTPlex.Worker.start_link(arg)
      # {HTTPlex.Worker, arg},
      # Start to serve requests, typically the last entry
      HTTPlexWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HTTPlex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HTTPlexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
