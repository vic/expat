defmodule Expat.DefTest do
  use ExUnit.Case
  use Expat, import: {Expat.Test.Named, [:age_to_vote]}

  expat def vote(age_to_vote()) do
    :voted
  end

  def vote(_) do
    :no_vote
  end

  expat def foo(x) do
    case x do
      age_to_vote() -> :voted
      _ -> :no_vote
    end
  end

  expat def anon() do
    fn age_to_vote() -> :voted end
  end

  test "expat def should add guard clause" do
    assert :voted == vote(20)
  end

  test "expat def when not match pattern guard" do
    assert :no_vote == vote(10)
  end

  test "expat def inner case" do
    assert :voted == foo(20)
  end

  test "expat def inner anon function" do
    assert :voted == anon().(20)
  end

end
