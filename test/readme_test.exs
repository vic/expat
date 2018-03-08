defmodule Expat.ReadmeTest do
  use ExUnit.Case
  use Expat

  require MyPatterns
  import MyPatterns

  require Voting
  import Voting

  doctest Expat
end
