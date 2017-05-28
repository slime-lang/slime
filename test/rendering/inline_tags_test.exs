defmodule RenderInlineTagsTest do
  use ExUnit.Case, async: true
  import Slime, only: [render: 1]

  test "render inline tags" do
    slime = ~s"""
    ul
      li#ll.first: a href="/a" A link
      li: a href="/b" B link
      li data-click-navigate="next": pagination: span Next
      li(data-click-navigate="prev"): pagination: span Prev
    """

    assert render(slime) == """
    <ul>
    <li class="first" id="ll"><a href="/a">A link</a></li>
    <li><a href="/b">B link</a></li>
    <li data-click-navigate="next"><pagination><span>Next</span></pagination></li>
    <li data-click-navigate="prev"><pagination><span>Prev</span></pagination></li>
    </ul>
    """ |> String.replace("\n", "")
  end

  test "render nested inline html" do
    slime = ~s"""
    .row: .col-lg-12: p Hello World
    """

    assert render(slime) == """
    <div class="row">
    <div class="col-lg-12">
    <p>Hello World</p>
    </div>
    </div>
    """ |> String.replace("\n", "")
  end

  test "render spaces in inline tags" do
    slime = ~s"""
    .row<>: p<> Hello World
    """

    assert render(slime) == ~s[ <div class="row"> <p>Hello World</p> </div> ]
  end

  test "render mixed nesting" do
    slime = ~s"""
    .wrap: .row: .col-lg-12
      .box: p One
      .box: p Two
    p Three
    """

    assert render(slime) == """
    <div class="wrap">
    <div class="row">
    <div class="col-lg-12">
    <div class="box">
    <p>One</p>
    </div>
    <div class="box">
    <p>Two</p>
    </div>
    </div>
    </div>
    </div>
    <p>Three</p>
    """ |> String.replace("\n", "")
  end

  test "render multiline inline content" do
    slime = ~S"""
    section inline content:
      subsequent lines #{"are"} separated
      by a newline character, which browsers render as space.
      <span>inline html #{"with interpolation"} is also OK</span>
      .
    section inline content
            without interpolation
    """

    html = """
    <section>inline content:
    subsequent lines are separated
    by a newline character, which browsers render as space.
    <span>inline html with interpolation is also OK</span>
    .</section><section>inline content
    without interpolation</section>
    """ |> String.trim_trailing

    assert render(slime) == html
  end
end
