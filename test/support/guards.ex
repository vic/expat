defmodule Expat.Test.Guards do

  use Expat

  defpat(one(1))
  defpat(age_to_vote(n) when n >= 18)
  defpat(t2({a, b}))

end
