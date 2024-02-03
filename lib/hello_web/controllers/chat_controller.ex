defmodule HelloWeb.TokenController do
  use HelloWeb, :controller

  def index(conn, _params) do
    json(conn, %{token: 
      if conn.private.plug_session["user_token"] !== nil do
        Phoenix.Token.sign(HelloWeb.Endpoint, "heartbeat auth", conn.assigns.current_user.username)
      else
        # Phoenix.Token.verify(MyAppWeb.Endpoint, "heartbeat auth", token, max_age: 86400)
        "guest"
      end
    })
  end

end
