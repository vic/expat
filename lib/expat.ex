defmodule Expat do

  @doc ~S"""
  Imports `defpat` and `expat` into scope.

      use Expat


  Since named patterns are just macros, they must
  be required and in scope at compile for using them.
  For this reason, the following syntax can be used
  to automatically require MyPatterns and import a list
  of named patterns from it.

      use Expat, import: {MyPatterns, [:age_to_vote]}

  This has the advantage of importing Expat and requiring
  the module (because we are going to use their macros) and
  importing just the given named patterns, because all the
  generated pattern macros have the same arity, they can be
  imported in a single step.
  """
  defmacro __using__([]) do
    quote do
      import Expat
    end
  end

  defmacro __using__(import: {module, names}) do
    quote do
      import Expat
      require unquote(module)
      import unquote(module), only: unquote(Enum.map(names, fn n -> {n, 1} end))
    end
  end

  alias Expat.Macro, as: EM

  @type simple_call :: {atom, keyword, list(Macro.t())}
  @type guarded_pattern :: {:when, list, [simple_call, ...]}
  @type pattern :: simple_call | guarded_pattern

  @doc ~S"""
  Define a new named pattern.

  This function takes only the function head as argument.
  You may also specify a guard, but never a do block.

  ## Examples

      defpat person(%Person{name: name})
      defpat adult(%{age: age}) when age > 18

  """
  @spec defpat(pattern) :: Macro.t()
  defmacro defpat(pattern) do
    EM.define_pattern(:defmacro, pattern)
  end

  @doc "Same as defpat but defines private patterns"
  @spec defpatp(pattern) :: Macro.t()
  defmacro defpatp(pattern) do
    EM.define_pattern(:defmacrop, pattern)
  end

  @doc ~S"""
  Expand an expression using named patterns.

  `expat` stands for `expand pattern` in an expression.
  It's also the name of the library :).

  Note that for this to work, the macros that
  define the named patterns should already have
  been compiled. For this reason, most of the
  time, named patterns should be defined on
  separate modules and imported for use.

  ## Example

  You define a module for your named patterns

     defmodule MyPatterns do
       use Expat

       @doc "Matches when n is legal age to vote"
       defpat adult_age(n) when n > 18
     end

  Then you can import it and use it's macros

     defmodule Foo do
        use Expat
        import MyPatterns

        def foo(x) do
          # Tell expat that we want the case
          # clauses being able to use guards
          # from the named pattern.
          #
          # foo(20) => :vote
          #
          expat case x do
            adult_age() -> :vote
          end
        end

        # You can also use expat at the `def`
        # level (or defp, defmacro, etc)
        #
        # In this case, we are asking expat to
        # also expand the named patterns it
        # sees on our function head, and the
        # guards it produces are added to our
        # function definition.
        #
        # vote(20) => {:voted, 20}
        # vote(20) => no function match error
        #
        expat def vote(adult_age(n: x)) do
          {:voted, x}
        end
     end

  You can even use `expat` only once at the module
  level, then all it's `def`, `case`, `fn`, ... will
  be able to use named patterns.


      use Expat
      import MyPatterns, only: [adult_age: 1]

      expat defmodule Ellections do

         def vote(adult_age(n: x)) do
           {:ok, x}
         end

         def vote(_), do: :error
      end

  """
  @spec expat(Macro.t()) :: Macro.t()
  defmacro expat(ast) do
    EM.expand_inside(ast, _: [escape: true, env: __CALLER__])
  end

  @doc false
  @spec expat(Macro.t(), Macro.t()) :: Macro.t()
  defmacro expat({n, m, a}, opts) do
    expr = {n, m, a ++ [opts]}
    EM.expand_inside(expr, _: [escape: true, env: __CALLER__])
  end
end
