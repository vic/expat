defmodule Expat.ExpansionTest do
  use ExUnit.Case

  import Expat.Test.Named
  use Expat

  test "defpat expansion returns guarded pattern" do
    {:when, _, [pattern, guard]} = age_to_vote(_: [escape: true])
    assert {:"age_to_vote n", _, _} = pattern
    assert {:>=, _, [{:"age_to_vote n", _, _}, 18]} = guard
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

    bound = [{:"age_to_vote n", 20}, {{:x, __MODULE__}, 20}]
    assert {20, ^bound} = Code.eval_quoted(q, [], __ENV__)
  end

  test "defpat expansion can add bindings to guarded pattern" do
    {:when, _, [pattern, guard]} = age_to_vote(n: v, _: [escape: true])
    assert {:=, _, [{:v, _, _}, {:"age_to_vote n", _, _}]} = pattern
    assert {:>=, _, [{:"age_to_vote n", _, _}, 18]} = guard
  end


end
