alias Hello.{Repo, Message, Room, Accounts}
import Ecto.Changeset

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hello.Repo.insert!(%Hello.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


lobby = Repo.insert!(%Room{name: "lobby", pass: ""})
hehe = Repo.insert!(%Room{name: "hehe", pass: ""})

{:ok,a} = Accounts.register_user(%{
	name: "IDK", 
	username: "EHE", 
	password: "aaaaaaaaaaaa", 
	email: "aa@aa", 
})

{:ok,a} = Accounts.register_user(%{
	name: "IDK2", 
	username: "HEHE2", 
	password: "aaaaaaaaaaaa", 
	email: "aa2@aa", 
})


unr=%{"hehe"=>%{"count"=>2, "last"=>"ligma"}}
unr = Map.put(unr, "lobby", %{"count"=>2, "last"=>"ballz"})

Repo.update(change(a, %{unreads: unr}))

Repo.insert!(%Message{user_id: a.id, text: "1L", room_id: lobby.id})
Repo.insert!(%Message{user_id: a.id, text: "1H", room_id: hehe.id})

IO.inspect Repo.get(Accounts.User, 1)