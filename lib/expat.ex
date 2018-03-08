defmodule Expat do
  defmacro __using__(_) do
    quote do
      import Expat
    end
  end

  alias Expat.Macro, as: EM

  @type simple_call :: {atom, keyword, list(Macro.t())}
  @type guarded_pattern :: {:when, list, [simple_call, ...]}
  @type pattern :: simple_call | guarded_pattern

  @doc """
  Define a new named pattern.

  This function takes only the function head as argument.
  You may also specify a guard, but never a do block.

  ## Examples

      defpat person(%{name: name})
      defpat adult(%{age: age}) when age > 18

  """
  @spec defpat(pattern) :: Macro.t()
  defmacro defpat(pattern) do
    EM.define_pattern(:defmacro, pattern)
  end

  @doc "Same as defpat but defines private patterns"
  @spec defpatp(pattern) :: Macro.t()
  defmacro defpatp(pattern) do
    EM.define_pattern(:defmacrop, pattern)
  end

  @doc """
  Expand an expression using named patterns.

  Note that for this to work, you have
  to wrap the expression inside `expat` and
  the patterns must be explicit function calls.

  ## Example

     defpat adult_age(n) when n > 18

     expat case 20 do
       adult_age(n: x) -> {:adult, x}
       x -> {:child, x}
     end
     => {:adult, 20}

  """
  @spec expat(Macro.t()) :: Macro.t()
  defmacro expat(ast) do
    EM.expand_inside(ast, _: [escape: true, env: __CALLER__])
  end

  @doc false
  @spec expat(Macro.t(), Macro.t()) :: Macro.t()
  defmacro expat({n, m, a}, opts) do
    expr = {n, m, a ++ [opts]}
    EM.expand_inside(expr, _: [escape: true, env: __CALLER__])
  end
end
