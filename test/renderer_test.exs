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
end
