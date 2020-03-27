import Config

config :todo, ecto_repos: [Todo.Repo]

import_config "#{Mix.env()}.exs"
