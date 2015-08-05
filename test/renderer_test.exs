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
end
