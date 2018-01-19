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

  test "attributes can contain dots in name" do
    slime = """
    div[v-on:click.prevent="click"]
    """
    assert render(slime) == ~s(<div v-on:click.prevent="click"></div>)

    slime = """
    div v-on:click.prevent="click"
    """
    assert render(slime) == ~s(<div v-on:click.prevent="click"></div>)
  end

  test "attributes values can be strings" do
    assert render(~s(meta name=variable content="one two"), variable: "test") ==
      ~s(<meta content="one two" name="test">)
  end

  test "attributes values can have spaces in them" do
    slime = """
    div style="display: none"
    """
    assert render(slime) == ~s(<div style="display: none"></div>)
  end

  test "attributes can span over multiple lines" do
    slime = """
    input[
    type="text"
    class="form-control"
    name="plop"]
    """
    assert render(slime) == ~s(<input class="form-control" name="plop" type="text">)
    slime = """
    section
      div [
        style="..."
        data-content="..."
      ]
        p
    """
    assert render(slime) ==
      ~s(<section><div data-content="..." style="..."><p></p></div></section>)
  end

  test "# provides shorthand for assigning ID attributes" do
    assert render(~s(span#id)) == ~s(<span id="id"></span>)
  end

  test "# provides shorthand for assigning class attributes" do
    assert render(~s(span.foo.bar)) == ~s(<span class="foo bar"></span>)
  end

  test "class name in .-dot shortcut can include dashes" do
    assert render(".my-css-class test") == ~s[<div class="my-css-class">test</div>]
  end

  test "text content can contain `.` character" do
    assert render(~s(div test.class)) == ~s(<div>test.class</div>)
  end

  test "attributes with interpolation" do
    assert render(~S(meta content="one#{two}"), two: "_one") == ~s(<meta content="one_one">)
  end

  test "attributes with qutation inside interoplation correctly" do
    assert render(~S[meta content="one#{to_string("three")}"]) == ~s(<meta content="onethree">)
  end

  test "attributes with tuples inside interoplation correctly" do
    assert render(~S[meta content="one#{tuple_size({"three", "four"})}"]) == ~s(<meta content="one2">)
  end

  test "parses attributes with elixir code" do
    assert render(
      ~S(meta content=@user.name), assigns: [user: %{name: "test"}]
    ) == ~s(<meta content="test">)

    assert render(
      ~S(meta content=user.name), user: %{name: "test"}
    ) == ~s(<meta content="test">)

    assert render(
      ~S(meta content=user["name"]), user: %{"name" => "test"}
    ) == ~s(<meta content="test">)

    assert render(
      ~S[meta content=Enum.join(a, b)], a: [1, 2, 3], b: ","
    ) == ~s(<meta content="1,2,3">)
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

  test "attributes are sorted by name" do
    assert render("a#bar.foo") == ~s(<a class="foo" id="bar"></a>)
    assert render("a.foo#bar") == ~s(<a class="foo" id="bar"></a>)
  end

  test "do not overescape quotes in attributes" do
    defmodule RenderHelperMethodWithQuotesArguments do
      @moduledoc false
      require Slime

      def static_path(path) do
        path
      end

      @slime ~s[link rel="stylesheet" href=static_path("/css/app.css")]
      Slime.function_from_string(:def, :pre_render, @slime, [], engine: Phoenix.HTML.Engine)

      def render do
        pre_render() |> Phoenix.HTML.Safe.to_iodata |> IO.iodata_to_binary
      end
    end

    assert RenderHelperMethodWithQuotesArguments.render ==
      ~s(<link href="/css/app.css" rel="stylesheet">)
  end
end
