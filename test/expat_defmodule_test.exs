# It should be possible to import named patterns
# only for using them at compile time
use Expat, import: {Expat.Test.Named, [:age_to_vote]}

# and tell expat to expand named patterns on a
# whole module definiton
expat defmodule Expat.DefModuleTest do
  use ExUnit.Case

  def vote(age_to_vote()) do
    :voted
  end

  test "expanded named pattern in function head" do
    assert :voted == vote(20)
  end
end
