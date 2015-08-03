defmodule SlimFastTest do
  use ExUnit.Case, async: true

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

  @htmleex "<!DOCTYPE html><html><head><meta description=\"slim fast\" name=\"keywords\"><title>Website Title</title></head><body><div class=\"class\" id=\"id\"><ul><li>1</li><li>2</li></ul></div></body></html>"

  test "render html" do
    assert SlimFast.evaluate(@slim, site_title: "Website Title") == @htmleex
  end
end
