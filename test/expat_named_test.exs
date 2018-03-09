defmodule Expat.NamedTest do
  use ExUnit.Case

  import Expat.Test.Named
  use Expat

  test "defpat defines a macro" do
    assert 1 == one()
  end

  test "can bind variables by position" do
    assert {:oh, :god} = t2(:oh, :god)
  end

  test "can bind variables by position for pattern with single variable" do
    assert 22 = foo(22)
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

  test "generated macro with guards can be used in with clause" do
   value =
     expat with age_to_vote(n: x) <- 20 do
             {:voted, x}
           end

   assert {:voted, 20} = value
  end
end
