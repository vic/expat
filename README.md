# Expat - Reusable, composable patterns in Elixir.

[![Travis](https://img.shields.io/travis/USER/REPO.svg)](https://travis-ci.org/vic/expat)
[![Hex.pm](https://img.shields.io/hexpm/v/expat.svg?style=flat-square)](https://hexdocs.pm/expat)

## About

Expat is a library for creating composable pattern matchers.

That means, whenever you find yourself writing complex or long
patterns in your functions, `expat` can be handy by allowing 
you to split your pattern into re-usable and composable bits.

These named pattern matchers defined with `expat` can be used,
for example, to match over large phoenix parameters and keep
your action definitions short and concise. Since programmers
read code all the time, their code should be optimized for
*communicating their intent*, so instead of having your brain
to parse all the way down the large structure pattern it
would be better to abstract that pattern with a name.

Also, as patterns get abstracted and split into re-usable
pieces they could be exported so other libraries (or your
own umbrella applications) can communicate the rules for
matching data being passed between them.

To read more about the motivation and where this library comes from,
you can read [the v0 README](https://github.com/vic/expat/blob/v0/README.md)

## `use Expat`

### Named Patterns

Let's start with some basic data examples. In Erlang/Elixir it's very
common to use tagged tuples to communicate between functions.
For example, a function that can fail might return `{:error, reason}`
or `{:ok, result}`. 

Of course these two element tuples are so small, that
most of the time it's better to use them as they *communicate the intent*
they are being used for. 

But, using them can help us understand the basics of how `expat` works, 
just remember that `expat` takes patterns, and is not limited 
to some particular data structure.

```elixir
    defmodule MyPatterns do
      use Expat

      defpat ok({:ok, result})
      defpat error({:error, reason})
    end
```

So, just like you'd be able to use `{:ok, result} = expr` to match
some expression, you can give the name `ok` to the `{:ok, result}` pattern.

Later on, at some other module, you can use those named patterns.

```elixir
     iex> import MyPatterns
     iex> Kernel.match?(ok(), {:ok, :hey})
     true
```

In the previous example, the `ok()` macro actually expanded to:


```elixir
     iex> Kernel.match?({:ok, _}, {:ok, :hey})
     true
```

Notice that even when the `ok` pattern definition says it
has an inner `result`, we didn't actually were interested in it,
so `ok()` just ensures the data is matched with the structure
mandated by its pattern and didn't bind any variable for us.

If we do need access to some of the pattern variables, we can bind
them by giving the pattern a `Keyword` of names to variables, 
for example:

```elixir
     # One nice thing about expat is you can use your patterns
     # anywhere you can currently write one, like in tests
     iex> assert error(reason: x) = {:error, "does not exist"}
     iex> x
     "does not exist"
```

And of course, if you bind all the variables in a pattern, you can
use its macro as a data constructor, for example:

```elixir
     iex> ok(result: "done")
     {:ok, "done"}
```

That's it for our tagged tuples example.

### Combining patterns

Now we know the basics of how to define and use named patterns,
let's see how we can combine them to form larger patterns.

Let's use some structs instead of tuples, as that might be
a more common use case.

```elixir
     defmodule Mascot do
        defstruct [:name, :age, :owner, :kind]
     end

     defmodule Person do
        defstruct [:name, :age, :country]
     end

     defmodule MyPatterns do
       use Expat

       defpat mexican(%Person{name: name, country: "MX"})

       defpat mexican_parrot(%Mascot{kind: :parrot, name: name,  age: age,
                                     owner: mexican(name: owner_name)})
     end

     iex> vic  = %Person{name: "vic", country: "MX"}
     ...> milo = %Mascot{kind: :parrot, name: "Milo", owner: vic, age: 4}
     ...>
     ...> # here, we are only interested in the owner's name
     ...> mexican_parrot(owner_name: name) = milo
     ...> name
     "vic"
```

And again, if you bind all the variables, it could be used as a data constructor

```elixir
     iex> mexican_parrot(age: 1, name: "Venus", owner_name: "Alicia")
     %Mascot{kind: :parrot, name: "Venus", age: 1, owner: %Person{country: "MX", name: "Alicia", age: nil}}
```

Then you could use those patterns in a module of yours

```elixir
      defmodule Feed do
         import MyPatterns

         def with_mexican_food(bird = mexican_parrot(name: name, owner_name: owner)) do
           "#{name} is happy now!, thank you #{owner}"
         end
      end
```

And the function head will actually match using the whole composite pattern, and only
bind those fields you are interested in using.


### Guarding patterns

Since expat v1.0 it's now possible to use guards on your pattern definitions, and they
will be expanded at the call-site.

For example, let's build this year's flawed election system.

```elixir
      defmodule Voting.Patterns do
        use Expat

        defpat mexican(%Person{country: "MX"})

        defpat adult(%{age: age}) when is_integer(age) and age >= 18
      end
```

Notice that the `adult` pattern matches anything with an integer age greater than 18 years
(mexico's legal age to vote) by using `when` guards on the definition.

Notice the `expat def can_vote?` part in the following code:

```elixir
       defmodule Voting do
          use Expat
          import Voting.Patterns
          
          def is_local?(mexican()), do: true
          def is_local?(_), do: false
          
          expat def can_vote?(mexican() = adult()), do: true
          def can_vote?(_), do: false
       end
```

`expat` stands for `expand pattern` in the following expression, *and*
expand their guards in the correct place. 

So our `can_vote?` function checks that the data given to it looks like
a mexican *and also* (since we are `=`ing two patterns), that the data
represents an adult with legal age to vote by using guards.

`expat` will work for `def`, `defmacro`, their private variants, `case`,
and `fn`. 

Actually you can give any expression into `expat`. And your patterns will
be expanded correctly within it. 

For example, the previous module could be written like:

```elixir
          # Since expat works at compile time, it and your pattern
          # macros need to be available if you want to expand them.
          use Expat, import: {Voting.Patterns, [:mexican, :adult]}

          expat defmodule Voting do

            def is_local?(mexican()), do: true
            def is_local?(_), do: false

            def can_vote?(mexican() = adult()), do: true
            def can_vote?(_), do: false
          end
```

Be sure to read the [documentation](https://hexdocs.pm/expat) and look at some of the [tests](https://github.com/vic/expat/tree/master/test).

## Installation

```elixir
def deps do
  [
    {:expat, "~> 1.0"}
  ]
end
```

