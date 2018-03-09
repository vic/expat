defmodule Expat.Test.Named do
  @moduledoc """
  Example named patterns defined with `defpat`
  """

  use Expat

  defpat one(1)
  defpat age_to_vote(n) when n >= 18
  defpat t2({a, b})
  defpat foo(bar)

end
