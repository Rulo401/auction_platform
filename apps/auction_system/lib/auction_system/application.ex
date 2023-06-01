defmodule AuctionSystem.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AuctionSystem.Repo,
      AuctionSystem.Supervisors.SystemSupervisor
    ]

    opts = [strategy: :one_for_one, name: AuctionSystem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
