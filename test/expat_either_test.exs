defmodule Expat.EitherTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Either using Union Patterns.

  In the code bellow note that the head pattern (`either`) is guarded.
  Because of this, building any of its tail patterns (`left` or `right`)
  needs to be done using their bang macro.

  The code bellow is exactly the same as:

      defpat either({tag, value}) when tag == :left or tag == :right
      defpat left(either(:left, value))
      defpat right(either(:right, value))

  """

  defpat (either({tag, value}) when tag == :left or tag == :right)
  | left(:left, value)
  | right(:right, value)

  test "left creates a tagged tuple" do
    assert {:left, 22} = left!(22)
  end

  test "right creates a tagged tuple" do
    assert {:right, 22} = right!(22)
  end

  test "either can also be used to pattern match" do
    expat case left!(22) do
            either(:left, 22) -> assert :ok
          end
  end

end
