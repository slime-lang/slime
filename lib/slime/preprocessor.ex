defmodule Slime.Preprocessor do
  @moduledoc """
  In order to make parsing Slime documents easier we run some simple
  transformations on the document to standardise the format.
  """

  @tabsize 2
  @soft_tab String.duplicate(" ", @tabsize)


  def process(document) do
    document
    |> expand_tabs
    |> split_into_lines
    |> Enum.flat_map(&split_inline_tags/1)
  end


  defp expand_tabs(document) do
    String.replace(document, ~r/\t/m, @soft_tab)
  end

  def split_into_lines(document) do
    String.split(document, "\n")
  end


  @inline_tag_regex ~r/\A(?<indent>\s*)(?<short_tag>(?:[\.#]?[\w-]*)+):(?<inline_tag>.*)/

  defp split_inline_tags(line) do
    @inline_tag_regex
    |> Regex.run(line, capture: :all_but_first)
    |> case do
      nil ->
        [line]

      [indent, short_tag, inline_tag] ->
        parent = indent <> short_tag
        inline = indent <> @soft_tab <> inline_tag
        [parent, inline]
    end
  end
end
