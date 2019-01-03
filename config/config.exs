use Mix.Config

config :tesla, adapter: Tesla.Adapter.Hackney

config :reddex,
  username: System.get_env("REDDIT_USERNAME"),
  password: System.get_env("REDDIT_PASSWORD"),
  client_id: System.get_env("REDDIT_CLIENT_ID"),
  client_secret: System.get_env("REDDIT_CLIENT_SECRET"),
  user_agent: System.get_env("REDDIT_USER_AGENT")
