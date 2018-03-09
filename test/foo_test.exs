defmodule Expat.FooTest do
  use ExUnit.Case
  use Expat

  defpat t2({a, b}) when a > b

  test "constructor with guard" do
    x = t2(2, 1, _: [build: true])
    assert {2, 1} == x
  end

  test "constructor with non matching guard" do
    assert_raise CaseClauseError, ~R/no case clause matching: {1, 2}/, fn ->
      t2(1, 2, _: [build: true])
    end
  end
end
