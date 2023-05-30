defmodule AuctionSystem.Schemas.Item do
  use Ecto.Schema
  alias AuctionSystem.Schemas.Skin
  import Ecto.Changeset

  schema "items" do
    belongs_to :skin, Skin
    field :seed, :integer
    field :sfloat, :float
  end

  def changeset(skin, params \\ %{}) do
    skin
    |> cast(params, [])
    |> validate_required([:skin_id, :seed, :sFloat])
  end
end
