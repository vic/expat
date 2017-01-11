defmodule Expat do
  @moduledoc """
  Define reusable composable patterns.
  """

  @doc """
  ## Examples

      defpat has_email(%{"email" => email})
      has_email() = %{"email" => "foo@bar.com"}

  """
  @spec defpat(pattern :: any) :: any

  defmacro defpat({name, _, [pattern]}) do
    Expat.Def.defpat(:defmacro, name, pattern)
  end

  @doc """
  Same as `defpat/1` but produces private patterns.
  """
  @spec defpatp(pattern :: any) :: any
  defmacro defpatp({name, _, [pattern]}) do
    Expat.Def.defpat(:defmacrop, name, pattern)
  end

end
