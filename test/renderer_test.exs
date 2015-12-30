defmodule RendererTest do
  use ExUnit.Case, async: true
  doctest Slime.Renderer

  use Slime.Renderer

  @slime """
  doctype html
  html
    head
      meta name="keywords" description="slime"
      title = site_title
    body
      #id.class
        ul
          = Enum.map [1, 2], fn x ->
            li = x
  """

  @html """
  <!DOCTYPE html><html>
  <head>
  <meta name=\"keywords\" description=\"slime\">
  <title>Website Title</title>
  </head>
  <body>
  <div class=\"class\" id=\"id\">
  <ul><li>1</li><li>2</li></ul></div>
  </body>
  </html>
  """ |> String.replace("\n", "")

  @eex """
  <!DOCTYPE html>
  <html>
  <head>
  <meta name="keywords" description="slime">
  <title><%= site_title %></title>
  </head>
  <body>
  <div class="class" id="id">
  <ul><%= Enum.map [1, 2], fn x -> %><li><%= x %></li><% end %></ul>
  </div>
  </body>
  </html>
  """ |> String.replace("\n", "")

  test "precompiles eex template" do
    assert Slime.Renderer.precompile(@slime) == @eex
  end

  test "render html" do
    assert render(@slime, site_title: "Website Title") == @html
  end

  @inline_slime ~S"""
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

  @inline_html """
  <html>
  <head>
  <title>Example</title>
  </head>
  <body>
  <table>
  <tr><td>Art 1</td><td>Desc 1</td></tr><tr><td>Art 2</td><td>Desc 2</td></tr>
  </table>
  </body>
  </html>
  """ |> String.replace("\n", "")

  test "render inline html" do
    articles = [%{name: "Art 1", desc: "Desc 1"}, %{name: "Art 2", desc: "Desc 2"}]
    assert render(@inline_slime, articles: articles) == @inline_html
  end

  test "render inline tags" do
    slime = ~s"""
    ul
      li#ll.first: a href="/a" A link
      li: a href="/b" B link
    """

    assert render(slime) == """
    <ul>
    <li class="first" id="ll"><a href="/a">A link</a></li>
    <li><a href="/b">B link</a></li>
    </ul>
    """ |> String.replace("\n", "")
  end

  test "render closed tag (ending with /)" do
    assert render(~s(img src="image.png"/)) == ~s(<img src="image.png"/>)
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
