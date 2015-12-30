defmodule Slime.Parser.AttributesKeyword do
  @moduledoc "
  Utilities for handling element attributes.
  "

  @doc """
  Merges multiply attributes values for keys specified in merge_rules.
  Attribute value may be given by string, list, or {:eex, args} node
  `merge_rules` should me an `%{attribute_name: joining_character}` map

  ## Examples
      iex> Slime.Parser.AttributesKeyword.merge(
      ...>   [class: "a", class: ["b", "c"], class: "d"],
      ...>   %{class: " "}
      ...> )
      [class: "a b c d"]

      iex> Slime.Parser.AttributesKeyword.merge(
      ...>   [class: "a", class: ["b", "c"], class: {:eex, content: "d"}],
      ...>   %{class: " "}
      ...> )
      [class: {:eex, content: ~S("a b c \#{d}"), inline: true}]
  """
  def merge(keyword_list, merge_rules) do
    Enum.reduce(merge_rules, keyword_list, fn ({attr, join}, result) ->
      case Keyword.get_values(result, attr) do
        [] ->
          result
        values ->
          values = merge_attribute_values(values, join)
          Keyword.put(result, attr, values)
      end
    end)
  end

  defp merge_attribute_values(values, join_by) do
    result = join_attribute_values(values, join_by)
    if Enum.any?(values, &dynamic_value?/1) do
      {:eex, content: ~s("#{result}"), inline: true}
    else
      result
    end
  end

  defp dynamic_value?({:eex, _}), do: true
  defp dynamic_value?(_), do: false

  defp join_attribute_values(values, join_by) do
    values |> Enum.map(&attribute_val/1) |> List.flatten |> Enum.join(join_by)
  end

  defp attribute_val({:eex, args}), do: "\#{" <> args[:content] <> "}"
  defp attribute_val(value), do: value
end
