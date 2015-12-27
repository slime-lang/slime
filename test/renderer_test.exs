defmodule RendererTest do
  use ExUnit.Case, async: true
  doctest SlimFast.Renderer

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

  @html "<!DOCTYPE html><html><head><meta name=\"keywords\" description=\"slim fast\"><title>Website Title</title></head><body><div class=\"class\" id=\"id\"><ul><li>1</li><li>2</li></ul></div></body></html>"

  @eex "<!DOCTYPE html><html><head><meta name=\"keywords\" description=\"slim fast\"><title><%= site_title %></title></head><body><div class=\"class\" id=\"id\"><ul><%= Enum.map [1, 2], fn x -> %><li><%= x %></li><% end %></ul></div></body></html>"

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
    articles = [%{name: "Art 1", desc: "Desc 1"}, %{name: "Art 2", desc: "Desc 2"}]
    assert render(@inline_slim, articles: articles) == @inline_html
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

  test "render inline tags" do
    slim = ~s"""
    ul
      li#ll.first: a href="/a" A link
      li: a href="/b" B link
    """

    assert render(slim) == ~s(<ul><li class="first" id="ll"><a href="/a">A link</a></li><li><a href="/b">B link</a></li></ul>)
  end

  test "render closed tag (ending with /)" do
    assert render(~s(img src="image.png"/)) == ~s(<img src="image.png"/>)
  end

  void_tags = ~w(
    area base br col embed hr img input keygen link menuitem meta param source track wbr
  )
  for tag <- void_tags do
    test "void element #{tag} requires no closing tag" do
      assert render(~s(#{unquote(tag)} data-foo="bar")) == ~s(<#{unquote(tag)} data-foo="bar">)
    end
  end
end
