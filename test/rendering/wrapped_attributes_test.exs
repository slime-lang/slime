defmodule RenderWrappedAttributesTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  test "rendering of boolean attributes" do
    assert render(~s(div [ab="ab" a] a)) == ~s(<div a ab="ab">a</div>)
    assert render(~s(div [a b="b"] c)) == ~s(<div a b="b">c</div>)
    assert render(~S(div ab="#{b} a" a), b: "b") == ~s(<div ab="b a">a</div>)
    assert render(~S(div[ab="a #{b}" a] a), b: "b") == ~s(<div a ab="a b">a</div>)
    assert render(~S<div[ab="a #{b.("c")}" a] a>, b: &(&1)) == ~s(<div a ab="a c">a</div>)
    assert render(~S<div[ab="a #{b.({"c", "d"})}" a] a>, b: fn {_, r} -> r end) == ~s(<div a ab="a d">a</div>)
    assert render(~s(script[defer async src="..."])) == ~s(<script async defer src="..."></script>)
  end

  test "render of wrapped attributes with elixir code values" do
    slime = ~s(meta[name=other content="one two"])
    assert render(slime, other: "1") == ~s(<meta content="one two" name="1">)
  end

  test "render of disabled wrapped attributes" do
    slime = "p {c=true}"
    assert render(slime) == ~s(<p>{c=true}</p>)
  end

  test "render of disabled wrapped attributes without space" do
    slime = "p{c=true}"
    assert render(slime) == ~s(<p>{c=true}</p>)
  end

  test ~s(show error message for div[id="test"} case) do
    assert_raise(Slime.TemplateSyntaxError, fn () ->
      render(~S(div[id="test"}))
    end)
  end

  test ~s(show error message for div [id="test"} case with leading space) do
    assert_raise(Slime.TemplateSyntaxError, fn () ->
      render(~S(div [id="test"}))
    end)
  end
end
