defmodule Expat.ExpansionTest do
  use ExUnit.Case

  import Expat.Test.Named
  use Expat

  defpat moo(x) when is_atom(x)

  test "no collission between two x from different expansions of same pattern" do
    # expansion must collect the two sub pattern guards
    assert e = {:when, _, [expr, guard]} = t2(moo(true), moo(false), _: [escape: true])
    # variable names look the same, have same name and context, but different counter
    assert "{x = true, x = false} when is_atom(x) and is_atom(x)" == Macro.to_string(e)
    assert {{:=, _, [{:x, xm, _}, true]}, {:=, _, [{:x, ym, _}, false]}} = expr
    # ensure their counter is different
    assert xm[:counter] != ym[:counter]
    # ensure the guarded vars correspond to the previous one
    assert {:and, _, [{:is_atom, _, [{:x, gxm, _}]}, {:is_atom, _, [{:x, gym, _}]}]} = guard
    assert xm[:counter] == gxm[:counter]
    assert ym[:counter] == gym[:counter]
  end

  @tag :skip
  test "once x is bound its inner can see the x binding"

  test "defpat expansion returns guarded pattern" do
    {:when, _, [pattern, guard]} = age_to_vote(_: [escape: true])
    assert {:n, m, _} = pattern
    assert m[:bindable] == :n
    assert m[:expat_counter] == m[:counter]
    assert {:>=, _, [{:n, g, _}, 18]} = guard
    assert g[:counter] == m[:counter]
  end

  test "can bind variables by their name to any elixir expression" do
    assert 22 = foo(bar: 22, _: [escaped: true])
  end

  test "pattern variables do not overwrite those in scope" do
    n = 1
    assert age_to_vote(n: x) = 20
    assert x == 20
    assert n == 1
  end

  test "meta variable used in guard is bound" do
    q =
      quote do
        assert age_to_vote(n: x) = 20
      end

    bound = [{{:x, __MODULE__}, 20}]
    assert {20, ^bound} = Code.eval_quoted(q, [], __ENV__)
  end

  test "defpat expansion can add bindings to guarded pattern" do
    {:when, _, [pattern, guard]} = age_to_vote(n: v, _: [escape: true])
    assert {:=, _, [{:v, _, _}, {:n, _, _}]} = pattern
    assert {:>=, _, [{:n, _, _}, 18]} = guard
  end
end
