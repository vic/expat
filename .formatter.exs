# Used by "mix format"
[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [expat: 1, expat: 2, defpat: 1, defpatp: 1],
  export: [
    locals_without_parens: [expat: 1, expat: 2, defpat: 1, defpatp: 1]
  ]
]
