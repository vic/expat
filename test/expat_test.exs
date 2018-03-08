defmodule Expat.Test do
  use ExUnit.Case

  import Expat.Test.Named

  use Expat

  test "defpat defines a macro" do
    assert 1 == one()
  end

  test "defpat expansion returns guarded pattern" do
    {:when, _, [pattern, guard]} = age_to_vote(_: [escape: true])
    assert {:"age_to_vote n", _, _} = pattern
    assert {:>=, _, [{:"age_to_vote n", _, _}, 18]} = guard
  end

  test "defpat expansion can add bindings" do
    {:when, _, [pattern, guard]} = age_to_vote(n: v, _: [escape: true])
    assert {:=, _, [{:v, _, _}, {:"age_to_vote n", _, _}]} = pattern
    assert {:>=, _, [{:"age_to_vote n", _, _}, 18]} = guard
  end

  test "generated macro can be used in left side of pattern match" do
    assert t2(b: t2(a: c)) = {1, {3, 4}}
    assert 3 == c
  end

  test "generated macro with guards can be used in case clause" do
    value =
      expat case(20) do
        age_to_vote(n: x) -> {:voted, x}
        _ -> :waited
      end

    assert {:voted, 20} = value
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
end
