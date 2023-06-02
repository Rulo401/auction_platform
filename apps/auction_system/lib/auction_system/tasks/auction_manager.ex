defmodule AuctionSystem.Tasks.AuctionManager do
  alias AuctionSystem.Repo
  alias AuctionSystem.Schemas.{Auction, Item, Skin}

  def auction_item(from, user_id, item_def, days) do
    auction_item(from, user_id, item_def, days, 0.1)
  end

  def auction_item(from, _, _, days, _) when not is_integer(days) or days < 1 do
    answer(from,{:error, "Duration days must be a positive integer"})
  end

  def auction_item(from, _, _, _, minBid) when not is_float(minBid) or minBid < 0.1 do
    answer(from,{:error, "The min bid must be float and greater than or equal to 0.1"})
  end

  def auction_item(from, user_id, item_def, days, minBid) do
    response = case item_def do
      %{skin_id: sid, seed: seed, sfloat: sfloat} when is_integer(seed) and seed >= 0 and is_float(sfloat) ->
        sk = Skin |> Repo.get(sid)
        cond do
          sk.minFloat > sfloat ->
            {:error, "Item float value is lower than the minimum accepted for this skin"}
          sk.maxFloat < sfloat ->
            {:error, "Item float value is higher than the maximum accepted for this skin"}
          true ->
            {:ok, item} = %Item{skin_id: sid, seed: seed, skinFloat: sfloat}
              |> Ecto.Changeset.change()
              |> Repo.insert()
            {:ok, auc} = %Auction{seller_id: user_id, item_id: item.id, minBid: minBid, end: get_end_date(days)}
              |> Ecto.Changeset.change()
              |> Repo.insert()
            {:ok, auc.id}
        end
      _ ->
        {:error, "Invalid item definition"}
    end
    answer(from,response)
  end

  defp get_end_date(days) do
    NaiveDateTime.utc_now()
      |> NaiveDateTime.add(days, :day)
      |> NaiveDateTime.truncate(:second)
  end

  def get_auction_data(from, auction_id) do
    auc = Auction |> Repo.get(auction_id) |> Repo.preload([item: [skin: :weapon]])
    response = %{
      weapon: auc.item.skin.weapon.name,
      skin: auc.item.skin.name,
      seed: auc.item.seed,
      skinFloat: auc.item.skinFloat,
      bid: if is_nil(auc.bid) do auc.minBid else auc.bid end,
      end: auc.end
      }
    answer(from, {:ok, response})
  end

  defp answer(from, response) when is_pid(from) do
    send(from, {:test, response})
  end

  defp answer(from, response) do
    GenServer.reply(from, response)
  end
end
