defmodule Cacheable do
  @moduledoc false
  import Cacheable.Utils

  defmacro __using__(opts) do
    caller_module = __CALLER__.module

    quote bind_quoted: [caller_module: caller_module, opts: opts] do
      import Cacheable.Utils

      @default_adapter Application.fetch_env!(:cacheable, :default_adapter)
      @adapter get_adapter(opts) || @default_adapter
      @cacheable_decorator_name Application.fetch_env!(:cacheable, :decorator_name)

      ensure_implements(@adapter, Cacheable.Adapter)

      Module.register_attribute(caller_module, @cacheable_decorator_name, accumulate: true)
      Module.register_attribute(caller_module, :cacheable_functions, accumulate: true)

      @on_definition Cacheable
      @before_compile Cacheable

      def __cacheable_adapter__(), do: @adapter
    end
  end

  def __on_definition__(env, kind, fun, args, _guards, _body) do
    opts = Module.get_attribute(env.module, :cacheable)
    function_signature = {kind, fun, args, opts}

    Module.put_attribute(env.module, :cacheable_functions, function_signature)
    Module.delete_attribute(env.module, :cacheable)
  end

  defmacro __before_compile__(env) do
    all_functions = get_module_functions(env)
    cacheable_functions = get_cacheable_functions(all_functions)
    Module.delete_attribute(env.module, :cacheable_functions)

    prelude = make_overridable(cacheable_functions)
    postlude = decorate_with_cache(cacheable_functions)

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  defp get_module_functions(env) do
    env.module
    |> Module.get_attribute(:cacheable_functions)
    |> Enum.reverse()
  end

  defp get_cacheable_functions(functions) do
    functions
    |> Enum.filter(&is_function_cacheable?/1)
    |> Enum.map(&validate_opts/1)
  end

  defp is_function_cacheable?({_, _fun, _args, []}), do: false
  defp is_function_cacheable?({:def, _fun, _args, _opts}), do: true
  defp is_function_cacheable?({_kind, _fun, _args, _opts}), do: false

  defp validate_opts({_kind, fun, args, [opts]}) do
    opts
    |> validate(:ttl, :number, required: true)
    |> validate(:key, :string, required: false)

    {fun, args, Keyword.take(opts, [:ttl, :key])}
  end

  defp make_overridable(cacheable_functions) do
    Enum.map(cacheable_functions, fn {fun, args, _opts} ->
      quote do
        defoverridable [{unquote(fun), unquote(Enum.count(args))}]
      end
    end)
  end

  defp decorate_with_cache(cacheable_functions) do
    Enum.map(cacheable_functions, fn {fun, args, opts} ->
      new_body =
        quote do
          opts = unquote(opts)
          cache_ttl = Keyword.fetch!(opts, :ttl)

          cache_key =
            Keyword.get(opts, :key) || generate_cache_key(__MODULE__, unquote(fun), unquote(args))

          case @adapter.get(cache_key) do
            {:error, :not_found} ->
              result = super(unquote_splicing(args))
              @adapter.save(cache_key, result, cache_ttl)
              result

            {:ok, result} ->
              result
          end
        end

      quote do
        def(unquote(fun)(unquote_splicing(args)), do: unquote(new_body))
      end
    end)
  end
end
