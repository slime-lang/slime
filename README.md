# SlimFast [![Build Status](https://travis-ci.org/doomspork/slim_fast.png?branch=master)](https://travis-ci.org/doomspork/slim_fast)

A [Slim](http://slim-lang.com) template parser in Elixir.

__Under very active development.__

```slim
#id.class
  p Hello World
```

```html
<div id="id" class="class">
  <p>Hello World</p>
</div>
```

## Using

```elixir
html = SlimFast.render(slim)
```

## Todo

+ [ ] EEx support
+ [ ] String interpolation
+ [ ] Attributes
+ [ ] Javascript tag support
+ [ ] HTML escaping

## License

Please see [LICENSE](https://github.com/doomspork/slim_fast/blob/master/LICENSE) for licensing details.
