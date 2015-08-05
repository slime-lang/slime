# SlimFast [![Build Status](https://travis-ci.org/doomspork/slim_fast.png?branch=master)](https://travis-ci.org/doomspork/slim_fast) [![Hex Version](https://img.shields.io/hexpm/v/slim_fast.svg)](https://hex.pm/packages/slim_fast)

A refreshing way to [slim](http://slim-lang.com) down your markup in Elixir.

To use SlimFast with [Phoenix] (http://www.phoenixframework.org/), see [PhoenixSlim](https://github.com/doomspork/phoenix_slim).

__UNDER ACTIVE DEVELOPMENT__

SlimFast is an [Elixir](http://elixir-lang.com) library for rendering [slim](http://slim-lang.com) templates as HTML; the name is a _very_ bad pun.  Easily turn this:

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

## Contributing

Please do.  New code should have accompanying tests.

## License

Please see [LICENSE](https://github.com/doomspork/slim_fast/blob/master/LICENSE) for licensing details.
