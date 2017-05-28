defmodule TagTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  test "dashed-strings can be used as tags" do
    assert render(~s(my-component text)) == ~s(<my-component>text</my-component>)
  end

  test "render nested tags" do
    slime = """
    #id.class
      p Hello World
    """

    assert render(slime) == ~s(<div class="class" id="id"><p>Hello World</p></div>)
  end

  test "render nested tags with text node" do
    slime = """
    #id.class
      p
        | Hello World
    """

    assert render(slime) == ~s(<div class="class" id="id"><p>Hello World</p></div>)
  end

  test "render closed tag (ending with /)" do
    assert render(~s(img src="image.png"/)) == ~s(<img src="image.png"/>)
  end

  test "render attributes and inline children" do
    assert render(~s(div id="id" text content)) == ~s(<div id="id">text content</div>)
    assert render(~s(div id="id" = elixir_func), elixir_func: "text") == ~s(<div id="id">text</div>)
  end

  test "parses inline children with interpolation" do
    assert render("div text \#{content}", content: "test") == ~s(<div>text test</div>)
  end

  void_elements = ~w(
    area base br col embed hr img input keygen link menuitem
    meta param source track wbr
  )
  for tag <- void_elements do
    test "void element #{tag} requires no closing tag" do
      html = render(~s(#{unquote(tag)} data-foo="bar"))
      assert html == ~s(<#{unquote(tag)} data-foo="bar">)
    end
  end
end
