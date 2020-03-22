defmodule Cacheable.Utils do
  @moduledoc false

  def get_adapter(opts) when is_list(opts), do: Keyword.get(opts, :adapter, nil)
  def get_adapter(_), do: raise("Unexpected options provided to Cacheable")

  def ensure_implements(module, behaviour) do
    all = Keyword.take(module.__info__(:attributes), [:behaviour])

    unless [behaviour] in Keyword.values(all) do
      raise "Expected #{inspect(module)} to implement #{inspect(behaviour)}"
    end

    module
  end

  def validate(opts, key, validator, required: required)
      when is_list(opts) and is_boolean(required) do
    not required || validate_presence(opts, key)

    value = Keyword.get(opts, key)

    if maybe_validate_value(value, validator),
      do: opts,
      else: validator_error(key, validator)
  end

  defp validate_presence(opts, key), do: Keyword.fetch!(opts, key)
  defp maybe_validate_value(_value = nil, _validator), do: true
  defp maybe_validate_value(value, validator), do: get_validator(validator).(value)
  defp get_validator(:number), do: &is_number/1
  defp get_validator(:string), do: &is_binary/1
  defp validator_error(key, validator), do: raise("#{key} should be #{validator}")

  def generate_cache_key(module, fun, args) do
    args = :crypto.hash(:sha256, :erlang.term_to_binary(args))
    "#{module}_#{fun}_#{Base.encode64(args)}"
  end
end
