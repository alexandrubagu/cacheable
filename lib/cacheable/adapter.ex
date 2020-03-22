defmodule Cacheable.Adapter do
  @moduledoc false
  @type key :: binary
  @type value :: term
  @type ttl :: integer

  @callback get(key) :: {:ok, term} | {:error, :not_found}
  @callback save(key, value, ttl) :: :ok | {:error, term}
  @callback delete(key) :: :ok | {:error, term}
  @optional_callbacks delete: 1
end
