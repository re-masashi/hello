defmodule Hello.Presence do
  use Phoenix.Presence,
    otp_app: :hello,
    pubsub_server: Hello.PubSub
end