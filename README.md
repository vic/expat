# Expat - Elixir reusable, composable patterns

[![Hex.pm](https://img.shields.io/hexpm/v/expat.svg)](https://hex.pm/packages/expat)
<a href="https://travis-ci.org/vic/expat"><img src="https://travis-ci.org/vic/expat.svg"></a>

Expat lets you split any pattern (be it for maps, lists, tuples, etc) into reusable bits, enabling you to combine them or export some patterns for reuse across Elixir libraries.

If you are looking to validate Elixir data structures you might want to look at [Spec](https://github.com/vic/spec). You can always first conform your data with Spec and then use Expat to pattern match the resulting conformed value and extract some value from it.

## Extracting patterns into reusable bits

Pattern matching on function heads is *the alchemist way* for dispatching to the
correct function on Elixir. However when patterns get very large (I've seen people who could split their code better having _large_ patterns on their phoenix controllers due to nested patterns like maps inside maps, or matching on many parameters) then code could turn a bit ugly (IMHO) forcing the reader's eyes to parse the whole pattern and then discover where the actual
function logic starts.

```elixir
# Like tinder, but for brains
# (actually a project from a friend who asked to codereview with her and thus expat was born)
defmodule Brainder do
  # brain match two subjects if their iq difference is less than ten
  # requires both of them to have email and location in their structure
  def brain_match(subject_a = %{
        "iq" => iq_a,
        "email" => _,
        "location" => %{
           "latitude" => _, "longitude" => _
        }
    }, 
    subject_b = %{   # and again, for subject_b
        "iq" => iq_b
        "email" => _,
        "location" => %{
           "latitude" => _, "longitude" => _
        }
    }) when abs(iq_a - ia_b) < 10 
  do
    # finally, actual logic here
  end
end
```

## Usage

Expat provides a `defpat/1` and `defpatp/1` that will define a pattern macro, thus moving away those patterns into reusable bits (expatriating them from the function head). Allowing you to avoid repeating yourself, and possibly exposing the pattern for others to use (when defined as public with `defpat`).

```elixir
defmodule Brainder do
  import Expat

  # defpat takes a name and a pattern to expand into.
  defpat iq(%{"iq" => iq})
  defpat email %{"email" => email}


  defpat latlng %{"latitude" => lat, "longitude" => lng}
  # patterns can be reused inside others by calling them
  defpat location %{"location" => latlng()}

  # intersecting patterns is done naturally by using the standard `=` match operator
  # thus subject is something that has iq, email and a location.
  defpat subject(iq() = email() = location())

  # the function head is more terse now, while still having access to the inner
  # iq on each subject, and ensuring both of them have the email and location structure.
  def brain_match(subject_a = subject(iq: iq_a), 
                  subject_b = subject(iq: iq_b))
  when abs(iq_a - ia_b) < 10 do
    # logic here, distance from function head to this line is shorter
    # while still explicit on what variables we can use here
  end
end
```

Notice how `subject(iq: iq_a)` tells expat we only are interested in the subject's IQ
and we replace the `iq` variable with another variable `iq_a` inside the subject pattern.
This way you explicitly say that you are just interested in some variables, all
other unbound variables will be replaced with `_` placeholders, thus expanding to: 

```elixir
%{
  "iq" => iq_a,
  "email" => _,
  "location" => %{
     "latitude" => _, "longitude" => _
  }
}
```

`subject(lat: 99.0)` would match all subjects on just that latitude, note that `lat` refers
to the `lat` *variable* pattern inside "location" (in elixir variables are just unbound patterns, assigned on match).
And `lat: 99.0` just replaces the `lat` pattern for another pattern: `99.0`, a number literal in this case.

```elixir
%{
  "iq" => _,
  "email" => _,
  "location" => %{
     "latitude" => 99.0, "longitude" => _
  }
}
```

If you call an expat pattern with a single non-keyword pattern replacement, all unbound variables inside of it
will be replaced with it. For example, if you want to just check for the structure without binding any variable you can use `subject(_)` which expands to:

```elixir
%{
  "iq" => _,
  "email" => _,
  "location" => %{
     "latitude" => _, "longitude" => _
  }
}
```

One nice thing about `expat` patterns is that because they are generated as macros, they can be used anywhere a
pattern can be used in Elixir, that is, as part of `with`, `case` clauses, or as the left side of a `=` match, like in tests

```elixir
test "dude is smart", %{dude: dude} do
  assert subject(iq: 200) = dude
end

test "subject(...) binds all variables inside it", %{dude: subject(...)} do
  assert iq > 200
  assert email == "terry.tao@example.com"
end
```

And by defining your patterns with `defpat` (instead of `defpatp`) you could export the `Briander.subject` pattern in a library and let other people use it for matching on things with that pattern (maybe before passing them to your api).

```elixir
def ZombieCoder do
  # search for food, not love
  require Brainder
 
  # find and eat juicy brains
  # we dont care for the whole Brainder subject, just iq and location
  def braaaaains() do
    World.population
    |> Stream.filter(fn Brainder.iq() = Brainder.latlng() when iq > 200 -> {lat, lng} end)
    |> Stream.map(&yuuuumi_eaaaat/1)
  end
 
  # If you bind all variables in a pattern, you can create data from it
  def make_zombbie() do
    Map.merge(Brainder.iq(0.7), Brainder.latlng(lat: 27, lng: 28))
  end
end
```

Look at [expat_test](https://github.com/vic/expat/blob/master/test/expat_test.exs) for more examples.


## Installation

[Available in Hex](https://hex.pm/packages/expat), the package can be installed
by adding `expat` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:expat, "~> 0.1"}]
end
```
 
