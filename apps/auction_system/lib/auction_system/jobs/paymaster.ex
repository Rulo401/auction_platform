defmodule AuctionSystem.Jobs.Paymaster do
  alias AuctionSystem.Schemas.Auction
  alias AuctionSystem.Repo
  import Ecto.Query

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
    case Repo.transaction(fn() -> pay_transaction() end) do
      {:ok, _} ->
        {:ok, nil}
      {:error, _} ->
        {:error, "Database error"}
    end
  end

  defp pay_transaction() do
    query = from au in Auction, where: not is_nil(au.bid) and not au.paid and au.end < datetime_add(^NaiveDateTime.utc_now(),0,"second"), preload: :seller, preload: :bidder
    pay_operation(Repo.all(query))
  end

  defp pay_operation([]) do  end

  defp pay_operation([auc | rest]) do
    Repo.update(Ecto.Changeset.change(auc.seller, balance: auc.seller.balance + auc.bid))
    Repo.update(Ecto.Changeset.change(auc.bidder, freezed: auc.bidder.freezed - auc.bid))
    Repo.update(Ecto.Changeset.change(auc, paid: true))
    pay_operation(rest)
  end

end
