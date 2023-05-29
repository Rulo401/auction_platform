defmodule AuctionSystem.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :nickname, :string
    field :balance, :float, default: 0.0
    field :freezed, :float, default: 0.0
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:balance, :freezed])
    |> validate_required([:nickname,:balance, :freezed])
    |> unique_constraint(:unique_user, name: :index_user_dup_entries)
  end
end
