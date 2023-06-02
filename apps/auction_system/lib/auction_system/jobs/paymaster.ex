defmodule AuctionSystem.Jobs.Paymaster do
  alias AuctionSystem.Schemas.Auction
  alias AuctionSystem.Repo
  import Ecto.Query

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      restart: :permanent
    }
  end

  def start_link(_) do
    {:ok, spawn_link( fn () -> run(60000) end)}
  end

  def start_paymaster(timeout) when is_integer(timeout) do
    spawn(fn () -> run(timeout) end)
  end

  defp run(timeout) do
    pay_now()
    receive do
      after timeout ->
        run(timeout)
    end
  end

  def pay_now() do
    pay_now(:ok, 0)
   #case Repo.transaction(fn() -> pay_transaction() end) do
   #  {:ok, _} ->
   #    :ok
   #  {:error, _} ->
   #    {:error, "Database error"}
   # end
  end

  defp pay_now({:error, _}, 0) do
    {:error, "Database error"}
  end

  defp pay_now({:ok, nil}, n) do
    {:ok, "#{inspect(n)} changes has been done"}
  end

  defp pay_now(_, n) do
    pay_now(Repo.transaction(fn() -> pay_transaction() end), n + 1)
  end

  defp pay_transaction() do
    query = from au in Auction, where: not is_nil(au.bid) and not au.paid and au.end < datetime_add(^NaiveDateTime.utc_now(),0,"second"), limit: 1, preload: :seller, preload: :bidder
    pay_operation(Repo.one(query))
  end

  defp pay_operation(nil) do nil end

  defp pay_operation(auc) do
    Repo.update(Ecto.Changeset.change(auc.seller, balance: auc.seller.balance + auc.bid))
    Repo.update(Ecto.Changeset.change(auc.bidder, freezed: auc.bidder.freezed - auc.bid))
    Repo.update(Ecto.Changeset.change(auc, paid: true))
  end

end
