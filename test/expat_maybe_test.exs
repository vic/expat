defmodule Expat.MaybeTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Using Unions to implement a simple Maybe type.

  Any non-nil value is an instance of Just.

  On the tests bellow notice that since the `just`
  pattern has a guard, we are using the `just!` constructor
  to create data from it and make sure the guard is satisfied.

  See also: expat_union_test.exs
  """

  defpat maybe(v)
  | nothing(nil)
  | ( just(y) when not is_nil(y) )

  test "nothing is nil" do
    assert nil == nothing!()
  end

  test "just is non nil" do
    assert 22 = just!(22)
  end

  test "just can be pattern matched" do
    assert just() = :jordan
  end

  test "nil cannot be pattern matched with just" do
    expat case nil do
      just() -> raise "Should not happen"
      nothing() -> assert :ok
    end
  end

end
