defmodule Hello.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    belongs_to :user, Hello.Accounts.User
    belongs_to :room, Hello.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :time, :sender, :room])
    |> validate_required([:text, :time, :sender, :room])
  end
end
