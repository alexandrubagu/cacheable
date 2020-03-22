use Mix.Config

# Configures decorator name
config :cacheable, decorator_name: :cacheable

# Configures default adapter
config :cacheable, default_adapter: Cacheable.Adapters.Cachex

# Configures Cachex adapter
config :cacheable, Cacheable.Adapters.Cachex, table_name: :cacheable
