defmodule AuctionSystem.Tasks.Auctioneer do
  alias AuctionSystem.Schemas.{User,Auction}
  alias AuctionSystem.Repo
  import Ecto.Query

  def bid(_, manager_pid, _) when not is_pid(manager_pid) do
    {:error, "Invalid manager pid"}
  end

  def bid(from, manager_pid, {user_id, auction_id, bid}) do
    response = process_bid({user_id, auction_id, bid})
    send(manager_pid, {:free, auction_id})
    cond do
      is_pid(from) ->
        send(from,{:test, response})
      true ->
        GenServer.reply(from, response)
    end
  end

  defp process_bid({user_id, auction_id, _}) when not is_integer(user_id) or not is_integer(auction_id) do
    {:error, "User_id and auction_id must be integers"}
  end

  defp process_bid({_, _, bid}) when not is_float(bid) or bid <= 0 do
    {:error, "Bid must be a positive float"}
  end

  defp process_bid({user_id, auction_id, bid}) do
    case Repo.transaction(fn -> bid_transaccion({user_id, auction_id, bid}) end) do
      {:error, :not_enough_balance} ->
        {:error, "User balance is not enough to bid the amount"}
      {:error, :auction_not_found} ->
        {:error, "Auction is closed or does not exist"}
      {:error, :lower_than_current_bid} ->
        {:error, "Bid must be higher than the current one"}
      {:error, :update_error} ->
        {:error, "Internal error. Try it later"}
      {:ok, response} ->
        response
    end
  end

  defp bid_transaccion({user_id, auction_id, bid}) do
    case Repo.one from u in User, where: u.id == ^user_id, lock: fragment("FOR UPDATE OF ?", u) do
      user when user.balance >= bid ->
        case Repo.one from a in Auction, where: a.id == ^auction_id and a.end > datetime_add(^NaiveDateTime.utc_now(),0,"second") do
          nil ->
            Repo.rollback(:auction_not_found)
          auc when auc.bid < bid ->
            prev_bidder = Repo.one from u in User, where: u.id == ^auc.bidder_id
            case prev_bidder do
              nil ->
                Repo.rollback(:update_error)
              _ ->
                nil
            end
            prev_bidder = prev_bidder |> User.changeset(%{balance: prev_bidder.balance + auc.bid, freezed: prev_bidder.freezed - auc.bid})
            case Repo.update(prev_bidder) do
              {:error, _} ->
                Repo.rollback(:update_error)
              _ ->
                nil
            end
            auc = auc |> Auction.changeset(%{bidder_id: user.id, bid: bid, end: increment_end_date(auc.end, 5)})
            case Repo.update(auc) do
              {:error, _} ->
                Repo.rollback(:update_error)
              _ ->
                nil
            end
            user = user |> User.changeset(%{balance: user.balance - bid, freezed: user.freezed + bid})
            case Repo.update(user) do
              {:ok, user} ->
                {:ok, user.balance}
              {:error, _} ->
                Repo.rollback(:update_error)
            end
          auc when is_nil(auc.bid) and auc.minBid < bid ->
            auc = auc |> Auction.changeset(%{bidder_id: user.id, bid: bid, end: increment_end_date(auc.end, 5)})
            case Repo.update(auc) do
              {:error, _} ->
                Repo.rollback(:update_error)
              _ ->
                nil
            end
            user = user |> User.changeset(%{balance: user.balance - bid, freezed: user.freezed + bid})
            case Repo.update(user) do
              {:ok, user} ->
                {:ok, user.balance}
              {:error, _} ->
                Repo.rollback(:update_error)
            end
          _ ->
            Repo.rollback(:lower_than_current_bid)
        end
      _ ->
        Repo.rollback(:not_enough_balance)
    end

  end

  defp increment_end_date(current_time, minutes) do
    proposed_time = NaiveDateTime.utc_now()
      |> NaiveDateTime.add(minutes, :minute)
      |> NaiveDateTime.truncate(:second)
    case NaiveDateTime.compare(current_time, proposed_time) do
      :lt ->
        proposed_time
      _ ->
        current_time
    end
  end
end
