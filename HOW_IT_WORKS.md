# How Pattern Expansion works in Expat.

When you define  `defpat foo(1)`, the ast inside foo (here `1`) is the code that will be placed at call-site. eg. `foo() = 1` expands to `1 = 1`.

That means it's actually possible to place *any* elixir code in there, and the `foo` macro will just expand it when called.

Now, since `expat`'s purpose in life is to help with pattern matching,
the ast inside foo is treated specially in the following cases:

- if it contains a variable like `defpat foo(x)` then x is _boundable_ by the caller of foo. The caller can bind it by name, like:
   `foo(x: 1) = 1` => `1 = 1`
  If x is not bound by the caller, like `foo()`, x will be replaced with an `_` , so `foo() = 1` is `_ = 1`

 - if it contains a guard like `defpat bar(y) when y > 10` then, the code of the guard will also be expanded, for example:
  `bar(y: 2)` will expand to `y  = 2 when y > 10`.

   Note however that since we have a guard to check, and `y` is being used in it, the variable `y` is preserved in expansion,, however this `y` is higenic (elixir's counter distingishes it from others) and will not bind any other y in your own scope. 

   To bind in your scope you do something like 
   `bar(y: u)` expands to `u = y when y > 10` and `u` is a variable you provided from your scope.

   So, you could bind bar's `y` with any expression, even other pattern expansions (just regular function calls)

    `bar(y: z = foo(x: 20))` will expand to `y = z = 20 when y > 20`
    this will also work: `bar(z = foo(20))`  since expat now supports positional arguments (variables get bound in the order they appear on the pattern)

 - If it contains a nested pattern expansion. For example, if you had
   `defpat t2({x, y}) when x > y` and later did
 `defpat teens(t2(bar(a), bar(b))) when a <  20 and b < 20`

    Then `teens` has two _bindable_ names, `:a` and `:b` and it will get expanded into a pattern like:
    `{a, b} when a < 20 and b < 20 and a > b and a > 10 and b > 10`
    That means inner guards get propagated into the calling expansion.


Now since `defpat` just captures the code inside the pattern for expanding it later, `defpat named(%{"name" => name})` allows you to expand `named` anywhere you can place a pattern in elixir, like on the left hand side of `=`

`named(x) = %{"name" => "vic"}` will expand to
`%{"name" => x} = %{"name" => "vic"}`, that's why you can use it on a function definition like:

`def index(conn, params = named(name)), do: ...`

However, for those containing guards, 

`def lalala(teens(m, n))` would by itself expand into:
`def lalala({m, n} when m < 20 and n < 20 and m > n and m > 10 and n > 10)`

*Of course* having a `when` in that context fails.
as it would do if you try:

```
iex(14)> {m, n} when m > n and m > 10 and n > 10 = {30, 20}
** (CompileError) iex:14: undefined function when/2
```
So, having guards was what introduced the `expat def` syntax:

`expat def lalala(teens(m, n))` expands correctly into:
`def lalala({m, n}) when m < 20 and n < 20 and m > n and m > 10 and n > 10`. 

