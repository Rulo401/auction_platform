defmodule AuctionSystem.Schemas.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
  end

  def changeset(category, params \\ %{}) do
    category
    |> cast(params, [])
    |> validate_required([:name])
    |> unique_constraint(:unique_category, name: :index_cat_dup_entries)
  end
end
