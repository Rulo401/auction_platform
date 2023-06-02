defmodule ClientApi do
  alias AuctionSystem.Servers.UserServer
  alias AuctionSystem.Servers.CreditServer
  alias AuctionSystem.Servers.MarketServer
  alias AuctionSystem.Servers.BidServer
  @type user_id() :: integer
  @type auction_id() :: integer
  @type category_id() :: integer
  @type category_name() :: String.t()
  @type weapon_id() :: integer
  @type weapon_name() :: String.t()
  @type skin_id() :: integer
  @type skin_name() :: String.t()
  @type balance() :: float
  @type item() ::  %{skin_id: skin_id(), seed: integer, sfloat: float}
  @type auction() :: %{weapon: String.t(), skin: String.t(), seed: integer, skinFloat: float, bid: float, end: NaiveDateTime.t()}

  #UserServer calls
  @spec create_user(username :: String.t()) :: {:ok, user_id()}
  def create_user(username) do
    GenServer.call(UserServer, {:create, username})
  end

  @spec delete_user(username :: String.t()) :: :ok
  def delete_user(username) do
    GenServer.call(UserServer, {:delete, username})
  end

  @spec login_user(username :: String.t()) :: {:ok, user_id()}
  def login_user(username) do
    GenServer.call(UserServer, {:login, username})
  end

  #CreditServer calls
  @spec deposit(user_id :: user_id(), amount :: float) :: {:ok, balance()}
  def deposit(user_id, amount) do
    GenServer.call(CreditServer, {:deposit, user_id, amount})
  end

  @spec withdraw(user_id :: user_id(), amount :: float) :: {:ok, balance()}
  def withdraw(user_id, amount) do
    GenServer.call(CreditServer, {:withdraw, user_id, amount})
  end

  @spec check_balance(user_id :: user_id()) :: {:ok, balance()}
  def check_balance(user_id) do
    GenServer.call(CreditServer, {:balance, user_id})
  end

  #BidServer calls
  @spec bid(user_id :: user_id(), auction_id :: auction_id(), amount :: float) :: {:ok, balance()}
  def bid(user_id, auction_id, amount) do
    GenServer.call(BidServer, {user_id, auction_id, amount})
  end

  #MarketServer calls
  @spec list_auctions() :: {:ok, list(auction_id())}
  def list_auctions() do
    GenServer.call(MarketServer, {:list_auctions, :all})
  end

  @spec list_auctions(method :: :category | :weapon | :skin, id :: category_id() | weapon_id() | skin_id()) :: {:ok, list(auction_id())}
  def list_auctions(method, id) do
    GenServer.call(MarketServer, {:list_auctions, method, id})
  end

  @spec list_categories() :: {:ok, list(category_id())}
  def list_categories() do
    GenServer.call(MarketServer, :list_category)
  end

  @spec list_weapons(category_id :: category_id()) :: {:ok, list({weapon_id(), weapon_name()})}
  def list_weapons(category_id) do
    GenServer.call(MarketServer, {:list_weapons, category_id})
  end

  @spec list_skins(weapon_id :: weapon_id()) :: {:ok, list({skin_id(), skin_name()})}
  def list_skins(weapon_id) do
    GenServer.call(MarketServer, {:list_skins, weapon_id})
  end

  @spec create_auction(user_id :: user_id(), item_def :: item(), days :: integer, minBid :: float) :: {:ok, auction_id :: auction_id()}
  def create_auction(user_id, item_def, days, minBid) do
    GenServer.call(MarketServer, {:auction_item, user_id, item_def, days, minBid})
  end

  @spec auction_data(auction_id :: auction_id()) :: {:ok, auction()}
  def auction_data(auction_id) do
    GenServer.call(MarketServer, {:auction_data, auction_id})
  end
end
