# Changelog

## v1.0.4

##### Enhancements
  
  * Add tagged unions
  * Report lines at expansion point not as pattern definition line.

## v1.0.3

##### Enhancements

  * Add HOW_IT_WORKS.md to add some details on how guards are expanded.
  * Add bang `!` macro for named pattern that can be used as constructor.
  
##### Bug Fixes

  * Pattern variables starting with `_` were able to be bound.

## v1.0.2

##### Enhancements

  * Allow positional arguments in adition to named bindings.
  * Document generated macros
  * Support `expat with`
  
  
## v1.0.1

##### Enhancements

  * Added a usage guide in README.md

##### Bug Fixes

  * Ensure pattern expassion happens in all arguments of a `def`


## v1.0.0

##### Enhancements

  * Major rewrite to let `defpat` support guards being defined on it
  * Introduced `expat` to expand patterns inside Elixir expressions
  
##### Deprecations

  * Removed the `...` syntax that introduced all pattern variables into scope.
    Now you must be explicit on what variables you want to bind.
    
  * Removed passing `_` to ignore all variables in pattern, now you must use
    the macro generated with zero arity, or bind all vars to `_`

