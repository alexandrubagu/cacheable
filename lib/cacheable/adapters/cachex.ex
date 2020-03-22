defmodule Cacheable.Adapters.Cachex do
  @moduledoc false
  @behaviour Cacheable.Adapter
  @cache_name Application.get_env(:cacheable, [__MODULE__, :cache_name], :cacheable)

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {Cachex, :start_link, [@cache_name, []]}
    }
  end

  def get(key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, value} -> {:ok, decode(value)}
    end
  end

  def save(key, value, ttl), do: Cachex.put(@cache_name, key, encode(value), ttl: ttl * 1000)
  def delete(key), do: Cachex.del(@cache_name, key)

  defp encode(data), do: data |> :erlang.term_to_binary() |> Base.encode64()
  defp decode(data), do: data |> Base.decode64!() |> :erlang.binary_to_term()
end
