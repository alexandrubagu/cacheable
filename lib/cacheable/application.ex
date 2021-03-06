defmodule Cacheable.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Cacheable.Adapters.Cachex
    ]

    opts = [strategy: :one_for_one, name: Cacheable.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
