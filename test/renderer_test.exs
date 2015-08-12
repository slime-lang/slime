defmodule RendererTest do
  use ExUnit.Case, async: true

  use SlimFast.Renderer

  @slim """
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
  """

  @html "<!DOCTYPE html><html><head><meta description=\"slim fast\" name=\"keywords\"><title>Website Title</title></head><body><div class=\"class\" id=\"id\"><ul><li>1</li><li>2</li></ul></div></body></html>"

  @eex "<!DOCTYPE html><html><head><meta description=\"slim fast\" name=\"keywords\"><title><%= site_title %></title></head><body><div class=\"class\" id=\"id\"><ul><%= Enum.map [1, 2], fn x -> %><li><%= x %></li><% end %></ul></div></body></html>"

  test "precompiles eex template" do
    assert precompile(@slim) == @eex
  end

  test "evaluates eex templates" do
    assert eval(@eex, site_title: "Website Title") == @html
  end

  test "render html" do
    assert render(@slim, site_title: "Website Title") == @html
  end

  @inline_slim ~S"""
  <html>
    head
      title Example
    <body>
      table
        = for a <- articles do
          <tr><td>#{a.name}</td><td>#{a.desc}</td></tr>
    </body>
  </html>
  """

  @inline_html "<html><head><title>Example</title></head><body><table><tr><td>Art 1</td><td>Desc 1</td></tr><tr><td>Art 2</td><td>Desc 2</td></tr></table></body></html>"

  test "render inline html" do
    assert render(@inline_slim,
      articles: [%{name: "Art 1", desc: "Desc 1"}, %{name: "Art 2", desc: "Desc 2"}]
    ) == @inline_html
  end

  test "render attributes with equal sign in value" do
    assert render(
      ~s(meta content="width=device-width, initial-scale=1" name="viewport")
    ) == ~s(<meta name="viewport" content="width=device-width, initial-scale=1">)
  end

  test "render tag with inline child containing dot should not produce class attribute" do
    assert render(~s(div test.class)) == ~s(<div>test.class</div>)
  end

  test "render tag with id after tag name should produce id attribute" do
    assert render(~s(span#id)) == ~s(<span id="id"></span>)
  end

  test "render html comments" do
    assert render(~s(/! html comment)) == ~s(<!--html comment-->)
  end

  test "render IE comments" do
    assert render(~s(/[if IE] html comment)) == ~s(<!--[if IE]>html comment<![endif]-->)
  end

  test "does not render code comments" do
    slim = """
    / code comment
      p.test
    """

    assert render(slim) == ~s(<p class="test"></p>)
  end

  test "render multiline varbatim text" do
    slim = """
    p
      | First line
        Second line
          Third Line with leading spaces
            Even more leading spaces
        And no spaces
    """
    assert render(slim) == String.strip("""
    <p>First line
    Second line
      Third Line with leading spaces
        Even more leading spaces
    And no spaces</p>
    """, ?\n)
  end

  test "render multiline varbatim text with trailing space" do
    slim = """
    p
      ' First line
        Second line
          Third Line with leading spaces
            Even more leading spaces
        And no spaces
    """
    assert render(slim) == String.strip("""
    <p>First line
    Second line
      Third Line with leading spaces
        Even more leading spaces
    And no spaces </p>
    """, ?\n)
  end

  test "render multiline varbatim text with empty first line" do
    slim = """
    p
      |
        First line
          Second Line with leading spaces
            Even more leading spaces
        And no spaces
    """
    assert render(slim) == String.strip("""
    <p>First line
      Second Line with leading spaces
        Even more leading spaces
    And no spaces</p>
    """, ?\n)
  end

  test "render multiline varbatim text with interpolation" do
    slim = ~S"""
    p
      |
        First line #{a}
          Second Line with leading spaces
            Even more leading #{b} spaces
        And no spaces
    """
    assert render(slim, a: "aa", b: "bb") == String.strip("""
    <p>First line aa
      Second Line with leading spaces
        Even more leading bb spaces
    And no spaces</p>
    """, ?\n)
  end

  test "render multiline varbatim text with tabs on some lines" do
    slim = """
    p
      |
        First line
          Second Line with leading spaces
    \t\tLeading tabs
        And no spaces
    """
    assert render(slim) == String.strip("""
    <p>First line
      Second Line with leading spaces
    Leading tabs
    And no spaces</p>
    """, ?\n)
  end

  test "render lines with 'do'" do
    defmodule RenderHelperMethodWithDoInArguments do
      require SlimFast

      def number_input(_, _, _) do
        "ok"
      end

      @slim ~s(= number_input f, :amount, class: "js-donation-amount")
      SlimFast.function_from_string(:def, :render, @slim, [:f])
    end

    assert RenderHelperMethodWithDoInArguments.render(nil) == "ok"
  end

  test "render dynamic template without external bindings" do
    slim = """
    - text = "test"
    = text
    """

    assert render(slim) == "test"
  end
end
