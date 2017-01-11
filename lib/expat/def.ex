defmodule Expat.Def do
  @moduledoc false

  def defpat(defmacro, name, pattern) do
    pattern = pattern |> Macro.escape
    quote do
      unquote(defmacro)(unquote(name)()) do
        unquote(pattern)
      end

      unquote(defmacro)(unquote(name)({:..., _, _})) do
        unquote(__MODULE__).pat(unquote(pattern), [], __CALLER__)
      end

      unquote(defmacro)(unquote(name)(args)) do
        unquote(__MODULE__).pat(unquote(pattern), [args], __CALLER__)
      end
    end
  end

  def pat(quoted, args, env) do
    quoted |> nested(env) |> pated(args, env)
  end

  defp pated(quoted, [], env) do
    quoted |> varify(env)
  end

  defp pated(quoted, [named], env) when is_list(named) do
    quoted |> named_replace(named, env) |> subst({:_, [], nil}, env)
  end

  defp pated(quoted, [pattern], env) do
    quoted |> subst(pattern, env)
  end

  defp nested(quoted, env) do
    quoted
    |> Macro.prewalk(fn
      expr = {name, _meta, []} when is_atom(name) -> expand(expr, env)
      expr -> expr
    end)
  end

  defp named_replace(quoted, named, env) do
    module = env.module
    quoted
    |> Macro.prewalk(fn
      expr = {name, _meta, x} when is_atom(name) and (x == nil or x == module) ->
        case Keyword.get(named, name) do
          nil -> expr
          subst -> expand(subst, env) |> varify(env)
        end
      expr -> expr
    end)
  end

  defp varify(quoted, env) do
    module = env.module
    quoted
    |> Macro.postwalk(fn
      {name, meta, x} when is_atom(name) and x == nil or x == module ->
        {name, [pat: :var] ++ meta, nil}
      expr -> expr
    end)
  end

  defp subst(quoted, replacement, env) do
    module = env.module
    quoted
    |> Macro.postwalk(fn
      expr = {_, [{:pat, _} | _], _} -> expr
      {_name, _meta, x} when x == nil or x == module -> replacement
      expr -> expr
    end)
  end

  defp expand(expr, env) do
    Macro.expand(expr, env)
  end

end
