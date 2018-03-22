defmodule Expat.UnionTest do
  use ExUnit.Case
  use Expat

  defpat nat
  | zero(0)
  | succ(nat() = n)

  test "zero is a nat" do
    assert nat() = zero()
  end

  test "succ of zero is a nat" do
    assert nat() = succ(zero())
  end

  test "succ takes only nats" do
    assert_raise MatchError, ~r/no match of right hand side value: 99/, fn ->
      succ(99)
    end
  end

  test "zero is tagged tuple" do
    assert {:nat, 0} = zero()
  end

  test "succ of zero is tagged tuple" do
    assert {:nat, {:nat, 0}} = succ(zero())
  end

end
