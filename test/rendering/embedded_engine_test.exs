defmodule RenderEmbeddedEngineTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1]

  test "render embedded javascript" do
    slime = """
    javascript:
      alert('Slime supports embedded javascript!')
    """
    assert render(slime) == ~s[<script>alert('Slime supports embedded javascript!')</script>]
  end

  test "render embedded javascript with blank lines" do
    slime = """
    javascript:
      alert('Slime supports embedded javascript!')

      alert('Slime supports embedded javascript!')
    """
    assert render(slime) == ~s"""
    <script>alert('Slime supports embedded javascript!')
    \nalert('Slime supports embedded javascript!')</script>
    """ |> String.strip(?\n)
  end

  test "render embedded multi-line nested javascript" do
    slime = """
    javascript:
      alert('Slime supports embedded javascript!')
       alert('Slime supports embedded javascript!')
        alert('Slime supports embedded javascript!')
      alert('Slime supports embedded javascript!')
    """
    assert render(slime) == ~s"""
    <script>alert('Slime supports embedded javascript!')
     alert('Slime supports embedded javascript!')
      alert('Slime supports embedded javascript!')
    alert('Slime supports embedded javascript!')</script>
    """ |> String.strip(?\n)
  end

  test "render embedded multi-line allow indent less than indent of first line" do
    slime = """
    javascript:
        alert('Slime supports embedded javascript!')
      alert('Slime supports embedded javascript!')
          alert('Slime supports embedded javascript!')
    """
    assert render(slime) == ~s"""
    <script>alert('Slime supports embedded javascript!')
    alert('Slime supports embedded javascript!')
      alert('Slime supports embedded javascript!')</script>
    """ |> String.strip(?\n)
  end

  test "render embedded empty javascript" do
    slime = """
    javascript:
    """
    assert render(slime) == ~s(<script></script>)
  end

  test "render embedded javascript with interpolation" do
    slime = """
    - a = "test"
    javascript:
      alert("Test \#{a}")
    """
    assert render(slime) == ~s[<script>alert("Test test")</script>]
  end

  test "render embedded css" do
    slime = """
    css:
      body {
        color: black;
      }
    """
    assert render(slime) == ~s(<style type="text/css">body {\n  color: black;\n}</style>)
  end

  test "render embedded css with interpolation" do
    slime = ~S"""
    - a = "white"
    css:
      #body {color: #{a};}
    """
    assert render(slime) == ~s[<style type="text/css">#body {color: white;}</style>]
  end

  test "render embedded elixir" do
    slime = """
    elixir:
      a =
        [1, 2, 3]
        |> Enum.map(&(&1 * &1))
    = Enum.join(a, ",")
    """
    assert render(slime) == ~s(1,4,9)
  end

  test "render embedded eex" do
    slime = """
    eex:
      Test: <%= "test" %>
    """
    assert render(slime) == ~s(Test: test)
  end

  defmodule TestEngine do
    @moduledoc false
    @behaviour Slime.Parser.EmbeddedEngine

    def render(text, _options) do
      {"div", attributes: [class: "test engine"], children: [text]}
    end
  end

  test "render markdown with custom embedded engine" do
    slime = """
    test_engine:
      Hello world!
    """
    assert render(slime) == ~s(<div class="test engine">Hello world!</div>)
  end
end
