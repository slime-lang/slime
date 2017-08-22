defmodule RenderCommentsTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  test "lines indented deeper than / are commented out" do
    slime = """
    / Code comment
      that spans over multiple lines
    /
     Code comment started
     on another line
    p.test
    / One-liner
    """
    assert render(slime) == ~s(<p class="test"></p>)
  end

  test "/! renders html comments" do
    assert render(~s(/! html comment)) == ~s(<!--html comment-->)
  end

  test "/! can span over multiple lines" do
    slime = """
    div
      /!
         HTML comments
      /! Have similar semantics
          to other text blocks:
              they can be nested, with indentation being converted to spaces
    """
    html = """
    <div><!--HTML comments--><!--Have similar semantics
     to other text blocks:
         they can be nested, with indentation being converted to spaces--></div>
    """ |> String.trim("\n")
    assert render(slime) == html
  end

  test "/! renders comments with interpolation" do
    slime = ~S(/! html comment with #{interpolation})
    html = """
    <!--html comment with a-->
    """ |> String.trim("\n")
    assert render(slime, interpolation: "a") == html
  end
end
