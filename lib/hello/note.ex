defmodule Hello.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :text, :string
    belongs_to :user, Hello.Accounts.User
    belongs_to :room, Hello.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :user, :room])
    |> validate_required([:text, :user, :room])
  end
end
