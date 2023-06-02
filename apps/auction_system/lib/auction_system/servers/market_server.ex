defmodule AuctionSystem.Servers.MarketServer do
  use GenServer
  alias AuctionSystem.Tasks.{FilterList, AuctionList, AuctionManager}
  @type list_by() :: {:list_weapons, integer} | {:list_skins, integer}
  @type item() ::  %{skin_id: integer, seed: integer, sfloat: float}
  @type auction_item() :: {:auction_item, user_id :: integer, item :: item(), days :: integer, minBid :: float} | {:auction_item, user_id :: integer, item :: item(), days :: integer}
  @type method() :: :list_category | list_by() | {:list_auction,:all} | {:list_auctions, atom(), integer} | auction_item() | {:auction_data, integer}

  @spec start_link([Supervisor.supervisor()]) :: {:ok, pid}
  def start_link([supervisor]) do
    GenServer.start_link(__MODULE__, supervisor, name: __MODULE__)
  end

  @impl true
  @spec init(Supervisor.supervisor()) :: {:ok, Supervisor.supervisor()}
  def init(supervisor) do
    {:ok, supervisor}
  end

  @impl true
  @spec handle_call(method(), GenServer.from(), Supervisor.supervisor()) :: {:noreply, Supervisor.supervisor()}
  def handle_call(:list_category, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: FilterList, start: {FilterList, :list_categories, [from]}})
    {:noreply, supervisor}
  end

  def handle_call({:list_weapons, category_id}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: FilterList, start: {FilterList, :list_weapons, [from, category_id]}})
    {:noreply, supervisor}
  end

  def handle_call({:list_skins, weapon_id}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: FilterList, start: {FilterList, :list_skins, [from, weapon_id]}})
    {:noreply, supervisor}
  end

  def handle_call({:list_auctions,:all}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: AuctionList, start: {AuctionList, :list_auctions, [from, :all]}})
    {:noreply, supervisor}
  end

  def handle_call({:list_auctions, method, arg}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: AuctionList, start: {AuctionList, :list_auctions, [from, method, arg]}})
    {:noreply, supervisor}
  end

  def handle_call({:auction_item, user_id, item_def, days, minBid}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: AuctionManager, start: {AuctionManager, :auction_item, [from, user_id, item_def, days, minBid]}})
    {:noreply, supervisor}
  end

  def handle_call({:auction_item, user_id, item_def, days}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: AuctionManager, start: {AuctionManager, :auction_item, [from, user_id, item_def, days]}})
    {:noreply, supervisor}
  end

  def handle_call({:auction_data, auction_id}, from, supervisor) do
    DynamicSupervisor.start_child(find_ds(supervisor), %{ id: AuctionManager, start: {AuctionManager, :get_auction_data, [from, auction_id]}})
    {:noreply, supervisor}
  end

  defp find_ds(supervisor) do
    list = Supervisor.which_children(supervisor)
    Enum.find_value(list, fn x -> filter_ds(x) end)
  end

  defp filter_ds(x) do
    case x do
      {:task_ds, child, :supervisor, _} ->
        child
      _ ->
        false
    end
  end
end
