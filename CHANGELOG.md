# Version 1.0.0

*Meet the all-new PEG based parser*

[Full changes list](https://github.com/slime-lang/slime/compare/v0.16...v1.0.0)

Thanks to all contributors! Special thanks to @little-bobby-tables

## Breaking Changes

* Mixing inline and nested children is no longer supported:
  ```
  p Inline
    span Nested
  ```

  This will now produce `<p>Inline span Nested</p>`
  instead of `<p>Inline<span>Nested</span></p>`.
  This is the expected behavior in ruby-slim.

* Embedded engine developers should handle dynamic code blocks in `render/2`.
  First argument of engine's render method is now a list of binaries and dynamic parts in the
  form of `{:eex, binary}`

* IE conditional comments are no longer supported #127

* Possible symbols for tag shortcuts is now limited to this:
  `.`, `#`, `@`, `$`, `%`, `^`, `&`, `+`, `!` plus any valid tag name

## Features & Fixes

* Improved support for code in attributes, for example:
  ```
  script src=static_path(@conn, "/js/zepto.min.js")
  ```
  is handled now #115
* Support for multiple inline-tags in one line #122
* Improved support for interpolation in text blocks. It is now possible to use helpers like `Phoenix.HTML.raw/1` inside `#{}` interpolation to avoid escaping by `eex` engine #130
* Added support for leading and trailing whitespaces in elixir output #120
* Multiline comments #126
* Support new config options: `default_tag`, `sort_attrs`
