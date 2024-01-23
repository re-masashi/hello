defmodule HelloWeb.ChatController do
	use HelloWeb, :controller

	def index(conn, _params) do
	  render(conn, :join)
	end

	def join(conn, %{"pass"=>pass,"room"=>room}) do
		IO.puts("pass:"<>pass)
		IO.puts("room:"<>room)
		render(conn, :join)
	end

	def create(conn, _params) do
	  render(conn, :create)
	end
end