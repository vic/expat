defmodule Expat.NatTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Natural numbers.

  The union pattern bellow is shorthand for:

     defpat nat({:nat, x})
     defpat zero(nat(0))
     defpat succ(nat(nat() = n))

  Note that both `zero` and `succ` are just using calling
  `nat` with some other pattern. Thus `zero()` builds `{:nat, 0}` and
  `succ` takes a single argument `n` which must itself be also a `nat()`

  See also expat_union_test.exs
  """

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

  def to_i(zero()), do: 0
  def to_i(succ(n)), do: 1 + to_i(n)

  test "convert a nat to int" do
    assert 3 = zero() |> succ |> succ |> succ |> to_i
  end


end
