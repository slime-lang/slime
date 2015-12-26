# SlimFast [![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/doomspork/slim_fast.png?branch=master
[travis]: https://travis-ci.org/doomspork/slim_fast
[hex-img]: https://img.shields.io/hexpm/v/slim_fast.svg
[hex]: https://hex.pm/packages/slim_fast
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> A refreshing way to slim down your markup in Elixir.

SlimFast is an [Elixir](http://elixir-lang.com) library for rendering
[Slim](http://slim-lang.com)-like templates as HTML.

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

```html
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


## Reference

### Attributes

Attributes can be assigned in a similar fashion to regular HTML.

```slim
a href="elixir-lang.org" target="_blank" Elixir
```
```html
<a href="elixir-lang.org" target="_blank">Elixir</a>
```

Elixir expressions can be used as attribute values using the interpolation
syntax.

```slim
a href="#{my_variable}" Elixir
```
```html
<a href="elixir-lang.org">Elixir</a>
```

Boolean attributes can be set using boolean values

```slim
input type="checkbox" checked=true
input type="checkbox" checked=false
```
```html
<input type="checkbox" checked>
<input type="checkbox">
```

There is a literal syntax for class and id attributes

```slim
.foo.bar
select.bar
#foo
body#bar
```
```html
<div class="foo bar"></div>
<select class="bar"></select>
<div id"foo"></div>
<body id="bar"></body>
```


### Code

Elixir can be written inline using `-` and `=`.

`-` evalutes the expression.
`=` evalutes the expression, and then inserts the value into template.

```slim
- number = 40
p = number + 2
```
```html
<p>42</p>
```

The interpolation syntax can be used to insert expressions into text.

```slim
- name = "Felix"
p My cat's name is #{name}
```
```html
<p>My cat's name is Felix</p>
```


### Comments

Lines can be commented out using the `/` character.

```slim
/ p This line is commented out
p This line is not
```
```html
<p>This line is not</p>
```

HTML `<!-- -->` comments can be inserted using `/!`
```slim
/! Hello, world!
```
```html
<!-- Hello, world! -->
```


### Conditionals

We can use the regular Elixir flow control such as the `if` expression.

```slim
- condition = true
= if condition do
  p It was true.
- else
  p It was false.
```
```html
p It was true.
```


## Phoenix

To use slim templates (and SlimFast) with [Phoenix][phoenix], please see
[PhoenixSlim][phoenix-slim].

[phoenix]: http://www.phoenixframework.org/
[phoenix-slim]: https://github.com/doomspork/phoenix_slim


## Precompilation

Templates can be compiled into module functions like EEx templates, using
functions `SlimFast.function_from_file/5` and
`SlimFast.function_from_string/5`.


## Differences to Ruby Slim

We aim for feature parity with the original [Slim](http://slim-lang.com)
implementation, but we deviate in some respects. We do this to be true to
Elixir – just like the original Slim implementation is true to its Ruby
foundations.

For example, in SlimFast you do

```slim
= if condition do
  p It was true.
- else
  p It was false.
```

where Ruby Slim would do

```slim
- if condition
  p It was true.
- else
  p It was false.
```

Note the `do` and the initial `=`, because we render the return value of the
conditional as a whole.


## Contributing

Feedback, feature requests, and fixes are welcomed and encouraged.  Please
make appropriate use of [Issues][issues] and [Pull Requests][pulls].  All code
should have accompanying tests.

[issues]: https://github.com/doomspork/slim_fast/issues
[pulls]: https://github.com/doomspork/slim_fast/pulls


## License

MIT license. Please see [LICENSE][license] for details.

[LICENSE]: https://github.com/doomspork/slim_fast/blob/master/LICENSE
