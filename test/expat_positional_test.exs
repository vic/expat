defmodule Expat.PoisitionalTest do
  use ExUnit.Case
  use Expat

  @moduledoc """
  Pattern variables can be binded by giving the
  macro a single keyword of names to variables.

  However, in some cases it comes handy to bind
  the variables positionally.

  If the last argument given to a expat macro is
  a keyword list, it's assumed to be used for
  bindings. Otherwise, it's used as a positional
  argument.

  The position of variables inside a pattern is
  it's position inside the pattern. Because of
  this, only use positional arguments for really
  simple patterns. (see expat_ast_test.exs)
  """

  defpat one(1)

  test "one expands to inner expression" do
    assert 1 = one()
  end

  defpat foo(bar)

  test "foo can bind inner variable with keyword" do
    assert 22 = foo(bar: 22)
  end

  test "foo can bind only variable if its not a kw" do
    assert 33 = foo(33)
  end

  defpat t2({a, b})

  test "t2 can bind variables by name" do
    assert {2, 1} = t2(a: 2, b: 1)
  end

  test "t2 can bind variables by position" do
    assert {2, 1} = t2(2, 1)
  end
end
