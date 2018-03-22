defmodule Expat.UnionTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Tagged union test.

  Pattern unions in Expat.

  The following example

  defpat foo
  | bar(1)
  | baz(2)

  is shorthand for:

  defpat foo({:foo, x})
  defpat bar(foo(1))
  defpat baz(foo(2))

  Note that when the first pattern has no arguments, it by default constructs
  a tagged tuple with its name, like in this case `{:foo, x}`.

  Thus, calling `bar` or `baz` will just expand the `foo` pattern itself with
  some arguments.

  See also:
    expat_nat_test.
  """


end
