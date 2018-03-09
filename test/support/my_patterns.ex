defmodule Pet do
  defstruct [:name, :age, :owner, :kind]
end

defmodule Person do
  defstruct [:name, :age, :country]
end

defmodule MyPatterns do
  use Expat
  defpat ok({:ok, result})
  defpat error({:error, reason})

  defpat mexican(%Person{name: name, country: "MX"})

  defpat mexican_parrot(%Pet{
           kind: :parrot,
           name: name,
           age: age,
           owner: mexican(name: owner_name)
         })
end

defmodule Voting.Patterns do
  use Expat

  defpat teenager(%{age: age}) when age > 9 and age < 11

  defpat adult(%{age: age}) when is_integer(age) and age >= 18
end

defmodule Voting do
  use Expat
  import MyPatterns
  import Voting.Patterns

  # our voting system is flawed, for sure.
  def flawed_can_vote?(mexican()), do: true

  expat def adult_can_vote?(mexican() = adult()) do
    true
  end

  import Voting.Patterns, only: []
end
