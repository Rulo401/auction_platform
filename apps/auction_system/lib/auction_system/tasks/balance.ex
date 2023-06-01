defmodule AuctionSystem.Tasks.Balance do
  alias AuctionSystem.Repo
  alias AuctionSystem.Schemas.User

  def balance(from, user_id) do
    response = case User |> Repo.get(user_id) do
      nil ->
        {:error,"User not found"}
      user ->
        {:ok, user.balance}
    end
    GenServer.reply(from, response)
  end

end
