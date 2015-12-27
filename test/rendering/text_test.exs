defmodule RenderTextTest do
  use ExUnit.Case, async: true
  use Slime.Renderer

  test "elements can have text content" do
    assert render("span Hi there!") == "<span>Hi there!</span>"
  end

  test "| allows multiline varbatim text" do
    slim = """
    p
      | First line
        Second line
          Third Line with leading spaces
            Even more leading spaces
        And no spaces
    """
    html = """
    <p>First line
    Second line
      Third Line with leading spaces
        Even more leading spaces
    And no spaces</p>
    """ |> String.strip(?\n)
    assert render(slim) == html
  end

  test "' allows multiline varbatim text with a trailing space" do
    slim = """
    p
      ' First line
        Second line
          Third Line with leading spaces
            Even more leading spaces
        And no spaces
    """
    html = """
    <p>First line
    Second line
      Third Line with leading spaces
        Even more leading spaces
    And no spaces </p>
    """ |> String.strip(?\n)
    assert render(slim) == html
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
    html = """
    <p>First line
      Second Line with leading spaces
        Even more leading spaces
    And no spaces</p>
    """ |> String.strip(?\n)
    assert render(slim) == html
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
    html = """
    <p>First line aa
      Second Line with leading spaces
        Even more leading bb spaces
    And no spaces</p>
    """ |> String.strip(?\n)
    assert render(slim, a: "aa", b: "bb") == html
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
    html = """
    <p>First line
      Second Line with leading spaces
    Leading tabs
    And no spaces</p>
    """ |> String.strip(?\n)
    assert render(slim, a: "aa", b: "bb") == html
  end
end
