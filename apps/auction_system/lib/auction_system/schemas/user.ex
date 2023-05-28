defmodule AuctionSystem.Schemas.User do
  use Ecto.Schema

  schema "user" do
    field :nickname, :string
    field :balance, :float, default: 0.0
    field :freezed, :float, default: 0.0
  end

  def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:balance, :freezed])
    |> Ecto.Changeset.validate_required([:nickname,:balance, :freezed])
  end
end
