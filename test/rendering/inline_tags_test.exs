defmodule RenderInlineTagsTest do
  use ExUnit.Case, async: true
  import Slime, only: [render: 1]

  test "render inline tags" do
    slime = ~s"""
    ul
      li#ll.first: a href="/a" A link
      li: a href="/b" B link
    """

    assert render(slime) == """
    <ul>
    <li id="ll" class="first"><a href="/a">A link</a></li>
    <li><a href="/b">B link</a></li>
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
end
