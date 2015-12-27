defmodule RenderWhitespaceTest do
  use ExUnit.Case, async: true
  use SlimFast.Renderer

  test "> inserts a space after the element" do
    assert render(~s(a> href="test" text)) == ~s(<a href="test">text</a> )
  end

  test "< inserts a space before the element" do
    assert render(~s(a< href="test" text)) == ~s( <a href="test">text</a>)
  end

  test "<> inserts a space before and after the element" do
    assert render(~s(a<> href="test" text)) == ~s( <a href="test">text</a> )
  end
end
