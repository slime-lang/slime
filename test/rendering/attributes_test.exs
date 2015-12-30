defmodule RenderAttributesTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  test "attributes values can be variables" do
    slime = """
    - value = "bar"
    div foo=value
    """
    assert render(slime) == ~s(<div foo="bar"></div>)
  end

  test "attributes values can have spaces in them" do
    slime = """
    div style="display: none"
    """
    assert render(slime) == ~s(<div style="display: none"></div>)
  end

  test "# provides shorthand for assigning ID attributes" do
    assert render(~s(span#id)) == ~s(<span id="id"></span>)
  end

  test "# provides shorthand for assigning class attributes" do
    assert render(~s(span.foo.bar)) == ~s(<span class="foo bar"></span>)
  end

  test "text content can contain `.` character" do
    assert render(~s(div test.class)) == ~s(<div>test.class</div>)
  end

  test "attributes values can contain `=` character" do
    template = ~s(meta content="width=device-width, initial-scale=1")
    html = ~s(<meta content="width=device-width, initial-scale=1">)
    assert render(template) == html
  end

  test "shorthand and literal class attributes are merged" do
    template = ~s(.class-one class="class-two")
    assert render(template) == ~s(<div class="class-one class-two"></div>)
  end

  test "attributes can have dynamic values" do
    assert render("div a=meta", meta: true) == ~s(<div a></div>)
    assert render("div a=meta", meta: "test") == ~s(<div a="test"></div>)
    assert render("div a=meta", meta: nil) == ~s(<div></div>)
    assert render("div a=meta", meta: false) == ~s(<div></div>)
  end

  test "rendering of boolean attributes" do
    assert render(~s(div [ab="ab" a] a)) == ~s(<div ab="ab" a>a</div>)
    assert render(~s(div [a b="b"] c)) == ~s(<div a b="b">c</div>)
    assert render(~S(div ab="#{b} a" a), b: "b") == ~s(<div ab="b a">a</div>)
    assert render(~S(div[ab="a #{b}" a] a), b: "b") == ~s(<div ab="a b" a>a</div>)
    assert render(~S<div[ab="a #{b.("c")}" a] a>, b: &(&1)) == ~s(<div ab="a c" a>a</div>)
    assert render(~S<div[ab="a #{b.({"c", "d"})}" a] a>, b: fn {_, r} -> r end) == ~s(<div ab="a d" a>a</div>)
    assert render(~s(script[defer async src="..."])) == ~s(<script defer async src="..."></script>)
  end

  test "do not overescape quotes in attributes" do
    defmodule RenderHelperMethodWithQuotesArguments do
      require Slime

      def static_path(path) do
        path
      end

      @slime ~s[link rel="stylesheet" href=static_path("/css/app.css")]
      Slime.function_from_string(:def, :pre_render, @slime, [], engine: Phoenix.HTML.Engine)

      def render do
        pre_render |> Phoenix.HTML.Safe.to_iodata |> IO.iodata_to_binary
      end
    end

    assert RenderHelperMethodWithQuotesArguments.render ==
      ~s(<link rel="stylesheet" href="/css/app.css">)
  end
end
