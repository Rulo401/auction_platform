defmodule AuctionSystem.Schemas.Weapon do
  use Ecto.Schema
  alias AuctionSystem.Schemas.Category
  import Ecto.Changeset

  schema "weapons" do
    field :name, :string
    belongs_to :category, Category
  end

  def changeset(weapon, params \\ %{}) do
    weapon
    |> cast(params, [])
    |> validate_required([:name, :category])
    |> unique_constraint(:unique_weapon, name: :index_weapon_duplicate_entries)
  end
end
