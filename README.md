# SlimFast [![Build Status](https://travis-ci.org/doomspork/slim_fast.png?branch=master)](https://travis-ci.org/doomspork/slim_fast) [![Hex Version](https://img.shields.io/hexpm/v/slim_fast.svg)](https://hex.pm/packages/slim_fast) [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

> A refreshing way to slim down your markup in Elixir.

SlimFast is an [Elixir](http://elixir-lang.com) library for rendering [slim](http://slim-lang.com) templates as HTML.

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

## Contributing

Feedback, feature requests, and fixes are welcomed and encouraged.  Please make appropriate use of [Issues](https://github.com/doomspork/slim_fast/issues) and [Pull Requests](https://github.com/doomspork/slim_fast/pulls).  All code should have accompanying tests.

## License

Please see [LICENSE](https://github.com/doomspork/slim_fast/blob/master/LICENSE) for licensing details.
