defmodule Expat.UnionTest do
  use ExUnit.Case
  use Expat

  @moduledoc ~S"""
  Expat Unions.

  Expat has an special syntax for defining pattern
  unions:

      defpat head_pattern | tail_patterns

  The following example (see expat_nat_test.exs)

      defpat foo
      | bar(:hello)
      | baz(:world)

  is just a syntax sugar for:

      defpat foo({:foo, x})
      defpat bar(foo(:hello))
      defpat baz(foo(:world))

  Note that when the head pattern has no arguments, by default it creates
  a tagged tuple with its name. In this example: `{:foo, x}`.

  Calling any of the tail patterns will just pass arguments into the
  head pattern.

  See also:
    expat_nat_test.exs
    expat_maybe_test.exs
    expat_either_test.exs
    expat_result_test.exs

  """

  defmodule Person do
    defstruct [:mood]
  end

  defpat person_in_mood(%Person{mood: mood})
  | sad_person(:sad)
  | happy_person(:happy)

  test "sad yields a person" do
    assert %Person{mood: :sad} = sad_person()
  end

  test "happy can be used to match" do
    expat case %Person{mood: :happy} do
            happy_person() -> assert :party
          end
  end

end
