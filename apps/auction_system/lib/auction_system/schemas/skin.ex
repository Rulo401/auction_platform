defmodule AuctionSystem.Schemas.Skin do
  use Ecto.Schema
  alias AuctionSystem.Schemas.Weapon
  import Ecto.Changeset

  schema "skins" do
    belongs_to :weapon_id, Weapon
    field :paint , :integer
    field :minFloat, :float
    field :maxFloat, :float
  end

  def changeset(skin, params \\ %{}) do
    skin
    |> cast(params, [])
    |> validate_required([:weapon_id, :paint, :minFloat, :maxFloat])
    |> unique_constraint(:unique_skin, name: :index_skins_dup_entries)
  end
end