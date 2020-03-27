import Config

config :todo, Todo.Repo,
  database: "elixir_todo",
  username: "postgres",
  password: "postgres",
  hostname: "0.0.0.0",
  port: "5432",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
