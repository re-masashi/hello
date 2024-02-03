defmodule Hello.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :pass, :string, redact: true
    has_many :messages, Hello.Message
    many_to_many :users, Hello.Accounts.User, join_through: "users_rooms"
    #has_many :notes, Hello.Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :pass])
    |> validate_required([:name, :pass])
    |> unsafe_validate_unique(:name, Hello.Repo)
    |> unique_constraint(:name)
  end
end
