defmodule Expat.Macro do
  @moduledoc """
             Expat internals for working with Macro.t()
             """ && false

  alias Expat, as: E

  @doc "Defines a named pattern"
  @spec define_pattern(defm :: :defmacro | :defmacrop, E.pattern()) :: E.pattern()
  def define_pattern(defm, pattern)

  def define_pattern(defm, {:|, _, [head, alts]}) do
    define_union_pattern(defm, union_head(head), collect_alts(alts))
  end

  def define_pattern(defm, pattern) do
    define_simple_pattern(defm, pattern)
  end


  @doc "Expands a pattern"
  @spec expand(pattern :: E.pattern(), opts :: list) :: Macro.t()
  def expand(pattern, opts) when is_list(opts) do
    binds = Keyword.delete(opts, :_)
    expat_opts = Keyword.get_values(opts, :_) |> Enum.concat()

    name = pattern_name(pattern)
    counter = :erlang.unique_integer([:positive])
    pattern = pattern |> remove_line |> set_expansion_counter(counter, name)
    guard = pattern_guard(pattern)

    value =
      pattern
      |> pattern_value
      |> bind(binds)
      |> make_under

    # remove names bound on this expansion
    bounds = bound_names_in_ast(value)
    # only delete the first to allow sub expansions take the rest
    binds = Enum.reduce(bounds, binds, &Keyword.delete_first(&2, &1))

    opts = [_: expat_opts] ++ binds
    {value, guard} = expand_arg_collecting_guard(value, guard, opts)

    result = (guard && {:when, [context: Elixir], [value, guard]}) || value

    code = cond do
      expat_opts[:escape] -> Macro.escape(result)
      expat_opts[:build] && guard ->
        quote do
          fn ->
            case unquote(value) do
              x when unquote(guard) -> x
            end
          end.()
        end
      :else -> result
    end

    if expat_opts[:show], do: show(code)
    code
  end

  def expand_inside(expr, opts) do
    Macro.postwalk(expr, &do_expand_inside(&1, opts))
  end

  ## Private parts bellow

  defp do_expand_inside({defn, c, [head, rest]}, opts)
       when defn == :def or defn == :defp or defn == :defmacro or defn == :defmacrop do
    args = pattern_args(head)
    guard = pattern_guard(head)

    {args, guard} = expand_args_collecting_guard(args, guard, opts)

    head =
      head
      |> update_pattern_guard(fn _ -> guard end)
      |> update_pattern_args(fn _ -> args end)

    {defn, c, [head, rest]}
  end

  defp do_expand_inside({:fn, c, clauses}, opts) do
    clauses =
      clauses
      |> Enum.map(fn {:->, a, [[e], body]} ->
        {:->, a, [[expand_calls_inside(e, opts)], body]}
      end)

    {:fn, c, clauses}
  end

  defp do_expand_inside({:case, c, [v, [do: clauses]]}, opts) do
    clauses =
      clauses
      |> Enum.map(fn {:->, a, [[e], body]} ->
        {:->, a, [[expand_calls_inside(e, opts)], body]}
      end)

    {:case, c, [v, [do: clauses]]}
  end

  defp do_expand_inside({:with, c, clauses}, opts) do
    clauses =
      clauses
      |> Enum.map(fn
        {:<-, a, [p, e]} ->
          {:<-, a, [expand_calls_inside(p, opts), e]}

        x ->
          x
      end)

    {:with, c, clauses}
  end

  defp do_expand_inside(ast, _opts), do: ast

  defp expand_args_collecting_guard(args, guard, opts) do
    Enum.map_reduce(args, guard, fn arg, guard ->
      expand_arg_collecting_guard(arg, guard, opts)
    end)
  end

  defp expand_arg_collecting_guard(ast, guard, opts) do
    expand_calls_collect({ast, {true, guard}}, opts)
  end

  defp expand_calls_collect({ast, {false, final}}, _), do: {ast, final}

  defp expand_calls_collect({ast, {true, initial}}, opts) do
    env = Keyword.get(opts, :_, []) |> Keyword.get(:env, __ENV__)

    Macro.traverse(ast, {false, initial}, fn x, y -> {x, y} end, fn
      x = {c, m, args}, y = {_, acc} when is_list(args) ->
        if to_string(c) =~ ~R/^[a-z]/ do
          expat_opts = [_: [escape: true]]

          args =
            args
            |> Enum.reverse()
            |> case do
              [o | rest] when is_list(o) ->
                if Keyword.keyword?(o) do
                  [expat_opts ++ o] ++ rest
                else
                  [expat_opts, o] ++ rest
                end

              x ->
                [expat_opts] ++ x
            end
            |> Enum.reverse()

          {c, m, args}
          |> Code.eval_quoted([], env)
          |> elem(0)
          |> collect_guard(acc)
          |> (fn {x, y} -> {x, {true, y}} end).()
        else
          {x, y}
        end

      x, y ->
        {x, y}
    end)
    |> expand_calls_collect(opts)
  end

  defp collect_guard({:when, _, [expr, guard]}, prev) do
    {expr, and_guard(prev, guard)}
  end

  defp collect_guard(expr, guard) do
    {expr, guard}
  end

  defp and_guard(nil, guard), do: guard
  defp and_guard(a, b), do: quote(do: unquote(a) and unquote(b))

  defp expand_calls_inside(ast, opts) do
    {expr, guard} =
      case ast do
        {:when, _, [ast, guard]} ->
          expand_arg_collecting_guard(ast, guard, opts)

        _ ->
          expand_arg_collecting_guard(ast, nil, opts)
      end

    (guard && {:when, [], [expr, guard]}) || expr
  end

  @doc "Make underable variables an underscore to be ignored" && false
  defp make_under(pattern) do
    Macro.prewalk(pattern, fn
      v = {_, m, _} ->
        (m[:underable] && {:_, [], nil}) || v

      x ->
        x
    end)
  end

  @doc "Mark variables in pattern that are not used in guards" && false
  defp mark_non_guarded(pattern) do
    vars_in_guards = pattern |> pattern_guard |> ast_variables

    value =
      pattern |> pattern_value
      |> Macro.prewalk(fn
        v = {_, [{:underable, true} | _], _} ->
          v

        v = {n, m, c} when is_atom(n) and is_atom(c) ->
          unless Enum.member?(vars_in_guards, v) do
            {n, [underable: true] ++ m, c}
          else
            v
          end

        x ->
          x
      end)

    pattern |> update_pattern_value(fn _ -> value end)
  end

  @doc "Marks all variables with the name they can be bound to" && false
  defp mark_bindable(pattern) do
    Macro.prewalk(pattern, fn
      {a, m, c} when is_atom(a) and is_atom(c) ->
        if to_string(a) =~ ~r/^_/ do
          {a, m, c}
        else
          {a, [bindable: a] ++ m, c}
        end

      x ->
        x
    end)
  end

  defp ast_variables(nil), do: []

  defp ast_variables(ast) do
    {_, acc} =
      Macro.traverse(ast, [], fn x, y -> {x, y} end, fn
        v = {n, _, c}, acc when is_atom(n) and is_atom(c) -> {v, [v] ++ acc}
        ast, acc -> {ast, acc}
      end)

    acc |> Stream.uniq_by(fn {a, _, _} -> a end) |> Enum.reverse()
  end

  defp bind(pattern, binds) do
    pattern
    |> Macro.prewalk(fn
      x = {_, [{:bound, _} | _], _} ->
        x

      {a, m = [{:bindable, b} | _], c} ->
        case List.keyfind(binds, b, 0) do
          nil ->
            {a, m, c}

          {_, var = {vn, vm, vc}} ->
            if m[:underable] do
              {vn, [bound: b] ++ vm, vc}
            else
              {:=, [bound: b], [var, {a, [bound: b] ++ m, c}]}
            end

          {_, expr} ->
            {:=, [bound: b], [{a, [bound: b] ++ m, c}, expr]}
        end

      x ->
        x
    end)
  end

  defp update_pattern_value(pattern, up) when is_function(up, 1) do
    update_pattern_head(pattern, fn {name, c, [value]} ->
      {name, c, [up.(value)]}
    end)
  end

  defp pattern_value(pattern) do
    {_, _, [value]} = pattern |> pattern_head
    value
  end

  defp pattern_args(pattern) do
    {_, _, args} = pattern |> pattern_head
    args
  end

  defp update_pattern_args(pattern, up) when is_function(up, 1) do
    update_pattern_head(pattern, fn {name, c, args} ->
      {name, c, up.(args)}
    end)
  end

  defp update_pattern_guard(pattern, up) when is_function(up, 1) do
    case pattern do
      {:when, x, [head, guard]} ->
        new_guard = up.(guard)

        if new_guard do
          {:when, x, [head, new_guard]}
        else
          head
        end

      head ->
        new_guard = up.(nil)

        if new_guard do
          {:when, [context: Elixir], [head, new_guard]}
        else
          head
        end
    end
  end

  defp pattern_guard(pattern) do
    case pattern do
      {:when, _, [_head, guard]} -> guard
      _ -> nil
    end
  end

  defp update_pattern_head(pattern, up) when is_function(up, 1) do
    case pattern do
      {:when, x, [head, guard]} ->
        {:when, x, [up.(head), guard]}

      head ->
        up.(head)
    end
  end

  defp pattern_head(pattern) do
    case pattern do
      {:when, _, [head, _guard]} -> head
      head -> head
    end
  end

  defp pattern_name(pattern) do
    {name, _, _} = pattern |> pattern_head
    name
  end

  defp meta_in_ast(ast, key) do
    {_, acc} =
      Macro.traverse(ast, [], fn
        ast = {_, m, _}, acc -> (m[key] && {ast, [m[key]] ++ acc}) || {ast, acc}
        ast, acc -> {ast, acc}
      end, fn x, y -> {x, y} end)

    acc |> Stream.uniq() |> Enum.reverse()
  end

  defp bindable_names_in_ast(ast) do
    ast |> meta_in_ast(:bindable)
  end

  defp bound_names_in_ast(ast) do
    ast |> meta_in_ast(:bound)
  end

  def show(ast) do
    IO.puts(Macro.to_string(ast))
    ast
  end

  defp remove_line(ast) do
    Macro.postwalk(ast, &Macro.update_meta(&1, fn x -> Keyword.delete(x, :line) end))
  end

  defp set_expansion_counter(ast, counter, pattern_name) do
    Macro.postwalk(ast, fn
      s = {x, m, y} when is_atom(x) and is_atom(y) ->
        cond do
          match?("_" <> _, to_string(x)) ->
            s
          m[:bindable] && !m[:expat_pattern] ->
            {x, m ++ [counter: counter, expat_pattern: pattern_name], y}
          :else ->
            s
        end

      x ->
        x
    end)
  end

  defp pattern_bang(defm, name, escaped, arg_names, opts) do
    vars = arg_names |> Enum.map(&Macro.var(&1, __MODULE__))
    argt = vars |> Enum.map(fn name -> quote do: unquote(name) :: any end)
    kw = Enum.zip([arg_names, vars])
    bang = :"#{name}!"

    quote do
      @doc """
      Builds data using the `#{unquote(name)}` pattern.

      See `#{unquote(name)}/0`.
      """
      @spec unquote(bang)(unquote_splicing(argt)) :: any
      unquote(defm)(unquote(bang)(unquote_splicing(vars))) do
        opts = unquote(kw) ++ [_: [build: true]] ++ unquote(opts)
        Expat.Macro.expand(unquote(escaped), opts)
      end
    end
  end

  defp pattern_zero(defm, name, pattern, escaped, arg_names, opts) do
    doc = pattern_zero_doc(name, pattern, arg_names)
    quote do
      @doc unquote(doc)
      unquote(defm)(unquote(name)()) do
        Expat.Macro.expand(unquote(escaped), unquote(opts))
      end
    end
  end

  defp pattern_zero_doc(name, pattern, arg_names) do
    value = pattern |> pattern_value
    guard = pattern |> pattern_guard

    code =
      cond do
        guard -> {:when, [], [value, guard]}
        true -> value
    end
    |> Macro.to_string()

    first_name = arg_names |> List.first()

    """
    Expands the `#{name}` pattern.

        #{code}


    ## Binding Variables

    The following variables can be bound by giving them
    to `#{name}` as keys on its last argument Keyword.

        #{arg_names |> Enum.map(&":#{&1}") |> Enum.join(", ")}

    For example:

        #{name}(#{first_name}: x)

    Where `x` can be any value, variable in your scope
    or another pattern expansion.
    Not mentioned variables will be unbound and replaced by
    an `_` at expansion site.
    Likewise, calling `#{name}()` with no argumens will
    replace all its variables with `_`.

    ## Positional Variables

    `#{name}` variables can also be bound by position,
    provided the last them is not a Keyword.

    For example:

        #{name}(#{Enum.join(arg_names, ", ")}, bindings = [])


    ## Bang Constructor

    The `#{name}!` constructor can be used to build data and
    make sure the guards are satisfied.

    Note that this macro can only be used as an expression
    and not as a matching pattern.

    For example:

        #{name}!(#{Enum.join(arg_names, ", ")})

    """
  end

  defp pattern_defs(defm, name, escaped, arg_names, opts) do
    arities = 0..length(arg_names)
    Enum.map(arities, fn n ->
      args = arg_names |> Enum.take(n)
      last = arg_names |> Enum.at(n)
      vars = args |> Enum.map(&Macro.var(&1, __MODULE__))
      argt = vars |> Enum.map(fn name -> quote do: unquote(name) :: any end)
      kw = Enum.zip([args, vars])

      quote do
        @doc """
        Expands the `#{unquote(name)}` pattern.

        See `#{unquote(name)}/0`.
        """
        @spec unquote(name)(unquote_splicing(argt), bindings :: keyword) :: any
        unquote(defm)(unquote(name)(unquote_splicing(vars), bindings))

        unquote(defm)(unquote(name)(unquote_splicing(vars), opts)) do
          opts = (Keyword.keyword?(opts) && opts) || [{unquote(last), opts}]
          opts = unquote(kw) ++ opts ++ unquote(opts)
          Expat.Macro.expand(unquote(escaped), opts)
        end
      end
    end)
  end

  defp define_simple_pattern(defm, pattern) do
    name = pattern_name(pattern)
    bindable = pattern |> mark_non_guarded |> mark_bindable
    escaped = bindable |> Macro.escape()

    opts =
      quote do
      [_: [env: __CALLER__, name: unquote(name)]]
    end

    arg_names = bindable |> pattern_args |> bindable_names_in_ast

    defs = pattern_defs(defm, name, escaped, arg_names, opts)
    zero = pattern_zero(defm, name, pattern, escaped, arg_names, opts)
    bang = pattern_bang(defm, name, escaped, arg_names, opts)

    defs = [bang, zero] ++ defs
    {:__block__, [], defs}
  end

  defp collect_alts({:|, _, [a, b]}) do
    [a | collect_alts(b)]
  end

  defp collect_alts(x) do
    [x]
  end

  defp union_head({name, _, x}) when is_atom(name) and (is_atom(x) or [] == x) do
    # foo({:foo, foo})
    {name, [], [{name, {name, [], nil}}]}
  end

  defp union_head(head), do: head

  defp define_union_pattern(defm, head, alts) do
    head_name = pattern_name(head)
    head_pats = define_simple_pattern(defm, head)
    alts_pats = alts |> Enum.map(fn alt ->
      alt = update_pattern_args(alt, &[{head_name, [], &1}])
      define_simple_pattern(defm, alt)
    end)
    {:__block__, [], [head_pats, alts_pats]}
  end


end
