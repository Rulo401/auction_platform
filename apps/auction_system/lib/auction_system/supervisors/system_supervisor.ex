defmodule AuctionSystem.Supervisors.SystemSupervisor do
  use Supervisor
  alias AuctionSystem.Supervisors.{MarketSupervisor,CreditSupervisor}
  alias AuctionSystem.Servers.UserServer
  alias AuctionSystem.Jobs.Paymaster

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}}
  def init(:ok) do
    children = [
      {UserServer, []},
      {Paymaster, []},
      {MarketSupervisor, []},
      {CreditSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
