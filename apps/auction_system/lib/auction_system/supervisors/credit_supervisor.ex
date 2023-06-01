defmodule AuctionSystem.Supervisors.CreditSupervisor do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(CreditSupervisor, :ok, name: CreditSupervisor)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: :balance_ds, strategy: :one_for_one, max_children: 250},
      {CreditServer, [self()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
