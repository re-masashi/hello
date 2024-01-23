import Config
config :hello, HelloWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}, ip: {0,0,0,0}], # Needed for Phoenix 1.2 and 1.4. Doesn't hurt for 1.3.
  url: [host: System.get_env("APP_NAME") <> ".gigalixirapp.com", port: 443]

config :hello, Hello.Repo,
	database: Path.expand("../hello.db", Path.dirname(__ENV__.file)),
	pool_size: 5,
	stacktrace: true,
	ssl: true