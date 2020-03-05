use Mix.Config

# Configures ETS Adapter
config :cacheable, Cacheable.Adapters.ETS, table_name: :cacheable
