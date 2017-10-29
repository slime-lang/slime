defmodule RenderTextTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  test "elements can have text content" do
    assert render("span Hi there!") == "<span>Hi there!</span>"
  end

  test "render content with interpolation" do
    assert render(~S"| text #{content}", content: "content") == "text content"
    assert render(~S"' text #{content}", content: "content") == "text content "
  end

  test "| allows multiline varbatim text" do
    slime = """
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
    """ |> String.trim("\n")
    assert render(slime) == html
  end

  test "' allows multiline varbatim text with a trailing space" do
    slime = """
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
    """ |> String.trim("\n")
    assert render(slime) == html
  end

  test "' without any text inserts whitespace" do
    slime = """
    p
      | Text
      '
      | with space
    """
    assert render(slime) == "<p>Text with space</p>"
  end

  test "render multiline varbatim text with empty first line" do
    slime = """
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
    """ |> String.trim("\n")
    assert render(slime) == html
  end

  test "render multiline varbatim text with interpolation" do
    slime = ~S"""
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
    """ |> String.trim("\n")
    assert render(slime, a: "aa", b: "bb") == html
  end

  test "render multiline varbatim text with tabs on some lines" do
    slime = """
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
    """ |> String.trim("\n")
    assert render(slime) == html
  end

  test "multiple sequential verbatim texts" do
    slime = """
    p
      | test
      | test 1
      | test 2
    """
    assert render(slime) == "<p>testtest 1test 2</p>"
  end

  test "multiple sequential verbatim texts with empty lines" do
    slime = """
    p

      | test

      | test1
    """
    assert render(slime) == "<p>testtest1</p>"
  end

  test "multiline verbatim text should be indented" do
    slime = """
    p
      ' test
        test
      = test
    """
    assert render(slime, test: "test") == "<p>test\ntest test</p>"
  end

  test "respect leading spaces in verbatim test" do
    slime = """
    p
      |  test
        test
         test
    """
    assert render(slime) == "<p> test\ntest\n test</p>"
  end

  test "verbatim text lines should be indented relative to first line" do
    slime = """
    p
      | foo
          foo
         bar
            baz
    """
    assert render(slime) == "<p>foo\n  foo\n bar\n    baz</p>"
  end

  test "verbatim text lines should be indented relative to first line with separate declaration" do
    slime = """
    p
      |
          foo
           bar
            baz
    """
    assert render(slime) == "<p>foo\n bar\n  baz</p>"
  end

  test "should unindent leading lines if there are less indented lines after them" do
    slime = """
    p
      |
          foo
        bar
            baz
    """
    assert render(slime) == "<p>foo\nbar\n    baz</p>"
  end
end
