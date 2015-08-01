# SlimFast

A [Slim](slim-lang.com) template parser in Elixir.

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

## License

Please see [LICENSE](https://github.com/doomspork/slim_fast/blob/master/LICENSE) for licensing details.
