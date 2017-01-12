# Expat - Elixir reusable, composable patterns <a href="https://travis-ci.org/vic/expat"><img src="https://travis-ci.org/vic/expat.svg"></a>

Expat lets you split patterns (be it for maps, lists, tuples, etc) into reusable bits being able to combine them and use them across Elixir libraries.

## Extracting patterns into reusable bits

Pattern matching on function heads is *the alchemist way* for dispatching to the
correct function on Elixir. However if a patterns get very large (I've seen people who could split their code better having _large_ patterns on their phoenix controllers due to nested patterns like maps inside maps, or matching on many parameters) then code could turn a bit ugly (IMHO) forcing the reader's eyes to parse the whole pattern and then discover where the actual
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

Expat provides a `defpat/1` and `defpatp/1` that will define a pattern macro, thus moving away those patterns into resusable bits (expatriating them from the function head). Allowing you to avoid duplicating patterns, and possibly exporting them (when defined as public with `defpat` for others to use)

```elixir
defmodule Brainder do
  include Expat

  # defpath takes a name and a pattern it will expand to:
  defpat iq(%{"iq" => iq})
  defpat email %{"email" => email}

  # patterns can be reused inside others
  defpat latlng %{"latitude" => lat, "longitude" => lng}
  defpat location %{"location" => latlng()}

  # *mixing* patterns is done naturally by using the `=` match operator
  # thus subject is something that has iq, email and a location.
  defpat subject(iq() = email() = location())

  # the function head is more terse now, while still having access to the inner
  # iq on each subject, and ensuring both of them have the same email, location fields
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
This way when you explictily state that you are interested in just some variables, all
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
And `lat: 99.0` just replaces the `lat` pattern for another pattern: `99.0` a number literal in this case.

```elixir
%{
  "iq" => _,
  "email" => _,
  "location" => %{
     "latitude" => 99.0, "longitude" => _
  }
}
```

If you want to just check for the structure without binding any variable use `subject(_)` which expands to:

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
pattern can be used in Elixir `with`, `case`, as the left side of a `=` match, like in tests

```elixir
test "dude is smart", %{dude: dude} do
  assert subject(iq: 200) = dude
end

test "subject(...) binds all variables inside it", %{dude: subject(...)} do
  assert iq > 200
  assert email == "terry.tao@example.com"
end
`````

For example, you could export the `Briander.subject` pattern in a library and have nice people to use it for matching on things with that pattern (maybe before passing them to your api).

```elixir
def ZombieCoder do
  # foood not loov
  require Brainder
 
  # find and eat juicy brains
  # wee zombiies dooont caaaaree for eemaaaaail, sooo just
  # match jummy IQQ and locatioon
  def braaaaains() do
    World.population
    |> Stream.filter(fn Brainder.iq() = Brainer.location() when iq > 200 -> {lat, lng} end)
    |> Stream.map(&yuuuumi_eaaaat/1)
  end
 
  # uze pattenrs to creaate new dataa!
  def make_zombbie() do
    Map.merge(Brainder.iq(0.7), Brander.location(lat: 27, lng: 28))
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
 
