defmodule ExampleParseBench do
  use Benchfella

  @slime ~S"""
  doctype html
  html
    head
      meta name="keywords" description="Slime"
      title = site_title
      javascript:
        alert('Slime supports embedded javascript!');
    body
      #id.class
        ul
          = Enum.map [1, 2], fn x ->
            li = x
  """

  bench "new parse" do
    Slime.Parser.parse(@slime)
  end

  bench "old ways" do
    @slime
    |> Slime.Preprocessor.process
    |> Slime.Parser.parse_lines
  end
end
