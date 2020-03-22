defmodule Cacheable.Support.FileAdapter do
  @moduledoc false
  @behaviour Cacheable.Adapter

  @filename "/tmp/file_cache.txt"
  File.write!(@filename, "")

  def get(key) do
    case System.cmd("grep", [key, @filename]) do
      {data, 0} -> {:ok, decode_cache_entry(data)}
      {"", _} -> {:error, :not_found}
    end
  end

  def save(key, value, ttl) do
    with :ok <- File.write!(@filename, encode_cache_entry(key, value, ttl)) do
      value
    end
  end

  defp encode_cache_entry(key, value, ttl), do: "\n#{key} #{ttl} #{encode(value)}"

  defp decode_cache_entry(data) do
    data
    |> String.trim()
    |> String.split(" ")
    |> Enum.at(_index_of_value = 2)
    |> decode()
  end

  defp encode(data), do: data |> :erlang.term_to_binary() |> Base.encode64()
  defp decode(data), do: data |> Base.decode64!() |> :erlang.binary_to_term()
end
