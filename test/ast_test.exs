defmodule Expat.AstTest.Patterns do
  use Expat

  defpat atom(name) when is_atom(name)
  defpat list(items) when is_list(items)

  defpat aliases({:__aliases__, list(meta), list(aliases)})

  defpat var({atom(name), list(meta), atom(context)})

  defpat local_call({atom(local), list(meta), list(args)})

  defpat head({atom(name), list(meta), params})
  defpat guarded({:when, list(meta), [expr, guard]})

  defpat defun({:def, list(meta), [head, [do: body]]})
end

defmodule Expat.AstTest do
  use ExUnit.Case
  use Expat

  @moduledoc """
  Tests showing how you can use Expat to
  work with data like Elixir quoted AST.
  """

  import __MODULE__.Patterns

  test "can match an atom" do
    assert atom() = :foo
  end

  test "can match and bind atom" do
    assert atom(name) = :hello
    assert name == :hello
  end

  expat test("can match a variable") do
    x = with var(name) <- quote(do: hello) do
          name
        end
    assert :hello == x
  end

  expat def call_name(local_call(name)) do
    name
  end

  test "can extract the name of a local call" do
    assert :foo = call_name(quote do: foo(1, 2))
  end

  expat test("can match a defun with case") do
    q = quote do
      def foo(a, b) do
        a + b
      end
    end

    x = case q do
          defun(head: head(name: n)) -> n
        end
    assert x == :foo
  end

  # unimport to prevent warning of it being unused
  # since it's used only at compilation time.
  import __MODULE__.Patterns, only: []
end
