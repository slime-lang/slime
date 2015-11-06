# SlimFast [![Build Status](https://travis-ci.org/doomspork/slim_fast.png?branch=master)](https://travis-ci.org/doomspork/slim_fast) [![Hex Version](https://img.shields.io/hexpm/v/slim_fast.svg)](https://hex.pm/packages/slim_fast) [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

> A refreshing way to slim down your markup in Elixir.

SlimFast is an [Elixir](http://elixir-lang.com) library for rendering [Slim](http://slim-lang.com) templates as HTML.

Easily turn this:

```slim
doctype html
html
  head
    meta name="keywords" description="slim fast"
    title = site_title
  body
    #id.class
      ul
        = Enum.map [1, 2], fn x ->
          li = x
```

Into this:

```erb
<!DOCTYPE html>
<html>
<head>
  <meta name="keywords">
  <title>Website Title</title>
</head>

<body>
  <div class="class" id="id">
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </div>
</body>
</html>
```

With this:

```elixir
SlimFast.render(slim, site_title: "Website Title")
```

## Phoenix

To use slim templates (and SlimFast) with [Phoenix](http://www.phoenixframework.org/), please see [PhoenixSlim](https://github.com/doomspork/phoenix_slim).

## Precompilation

Templates can be compiled into module functions like EEx templates, using functions
`SlimFast.function_from_file/5` and `SlimFast.function_from_string/5`.

## Differences to Ruby Slim

We aim for feature parity with the original [Slim](http://slim-lang.com) implementation, but we deviate in some respects. We do this to be true to Elixir – just like the original Slim implementation is true to its Ruby foundations.

For example, in SlimFast you do

```
= if condition do
  p It was true.
- else
  p It was false.
```

where Ruby Slim would do

```
- if condition
  p It was true.
- else
  p It was false.
```

Note the `do` and the initial `=`, because we render the return value of the conditional as a whole.

## Contributing

Feedback, feature requests, and fixes are welcomed and encouraged.  Please make appropriate use of [Issues](https://github.com/doomspork/slim_fast/issues) and [Pull Requests](https://github.com/doomspork/slim_fast/pulls).  All code should have accompanying tests.

## License

Please see [LICENSE](https://github.com/doomspork/slim_fast/blob/master/LICENSE) for licensing details.
