defmodule Expat.ExpatTest.Patterns do
  use Expat
  defpat list(x) when is_list(x)
  defpat atom(x) when is_atom(x)
  defpat one(1)
  defpat aa({a, a})
  defpat t2({a, b})
  defpat call({atom(name), list(meta), list(args)})
  defpat var({atom(name), list(meta), atom(context)})
end

defmodule Expat.ExpatTest do
  use ExUnit.Case
  use Expat

  alias __MODULE__.Patterns, as: P
  import P

  expat def foo(t2(one(), atom(x))) do
    x
  end

  expat def calling(call(name)) do
    name
  end

  expat def variable(var(name)) do
    name
  end

  test "can expand nested pattern" do
    assert :foo = foo({1, :foo})
  end

  test "calling home" do
    assert :home = calling(quote do: home())
  end

  test "a variable name" do
    assert :x = variable({:x, [], nil})
  end

  test "aa places same value twice" do
    assert {2, 2} = aa(2)
  end

  test "can use t2 as constructor with named vars" do
    assert {3, {1, 2}} = t2(b: t2(a: 1, b: 2), a: 3)
  end

  import P, only: []
end
