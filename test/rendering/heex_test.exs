defmodule FunctionComponentTest do
  use ExUnit.Case, async: true

  import Slime.Renderer, only: [precompile_heex: 1]

  test "function components work with scalar attributes" do
    slime = ":my_function foo=1"
    heex = ~s(<.my_function foo="1"></.my_function>)
    assert precompile_heex(slime) == heex
  end

  test "function components work with assigns" do
    slime = ":my_function foo=one"
    heex = ~s(<.my_function foo={one}></.my_function>)
    assert precompile_heex(slime) == heex
  end

  test "function components work with inner html" do
    slime = ~s"""
    :my_function
      div
        | Inner Html
    """

    heex = ~s(<.my_function><div>Inner Html</div></.my_function>)

    assert precompile_heex(slime) == heex
  end

  test "function components work with inner html and assigns" do
    slime = ~s"""
    :my_function foo=bar
      div
        | Inner Html
    """

    heex = ~s(<.my_function foo={bar}><div>Inner Html</div></.my_function>)

    assert precompile_heex(slime) == heex
  end

  test "assigns work in interpolated string expressions" do
    slime = ~s(div id="user_\#{id}")
    heex = ~s(<div id={"user_\#{id}"}></div>)
    assert precompile_heex(slime) == heex
  end

  test "function components work when called with full module name" do
    slime = ":MyApp.module.city"
    heex = "<MyApp.module.city></MyApp.module.city>"
    assert precompile_heex(slime) == heex
  end

  test "function components work with assigns when called with full module name" do
    slime = ":MyApp.module.city name=city_name"
    heex = "<MyApp.module.city name={city_name}></MyApp.module.city>"
    assert precompile_heex(slime) == heex
  end
end
