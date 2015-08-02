defmodule SlimFast.Parser do
  @blank    ""
  @content  "|"
  @script   "="
  @smart    "-"

  def parse_lines([]), do: []
  def parse_lines([h|t]), do: [parse_line(h)|parse_lines(t)]

  def parse_line(line) do
    {indentation, line} = strip_line(line)

    line = line
           |> String.first
           |> parse_line(line)

    {indentation, line}
  end

  defp attribute_val("\"" <> value), do: String.slice(value, 0..-2)
  defp attribute_val(value), do: parse_eex("=" <> value)

  defp css_classes(input) do
    css = ~r/\.([\w-]{1,})/
          |> Regex.scan(input)
          |> Enum.flat_map(fn ([_|class]) -> class end)

    cond do
      length(css) > 0 -> [class: css]
      true -> []
    end
  end

  defp html_attribute(attribute) do
    [key, value] = attribute |> String.split("=")
    key = key
          |> String.strip
          |> String.to_atom

    value = value
            |> String.strip
            |> attribute_val

    {key, value}
  end

  defp html_attributes(input) do
    ~r/[\w-]+\s*=\s*("[\s\w]+"|\w+)/
    |> Regex.scan(input)
    |> Enum.reduce([], fn ([h|_], acc) -> [html_attribute(h)|acc] end)
  end

  defp html_id(input) do
    case Regex.run(~r/^#([\w-]{1,})/, input) do
      [_, id] -> [id: id]
      _ -> []
    end
  end

  defp inline_children(@blank), do: []
  defp inline_children("=" <> content = input), do: [parse_eex(input)]
  defp inline_children(input), do: [String.strip(input, ?")]

    defp parse_div(input) do
    {:div, parse_metdata(input)}
  end

  defp parse_eex(input) do
    script = input
             |> String.split(~r/[-|=|==]/)
             |> List.last
             |> String.lstrip
    inline = String.starts_with?(input, "=")
    {:eex, content: script, inline: inline}
  end

  defp parse_line(@blank, _line), do: @blank
  defp parse_line(@content, line), do: line |> String.slice(2..-1)
  defp parse_line(@script, line), do: parse_eex(line)
  defp parse_line(@smart, line), do: parse_eex(line)

  defp parse_line(_, line) do
    parts = ~r/^\s*(?<tag>\w*(?:[#.]\w+)*)(?<attrs>(?:\s*[\w-]+\s*=(".+"|\w+))*)(?<tail>.*)/
            |> Regex.named_captures(line)

    {tag, basics} = parse_tag(line)

    additional = parts["attrs"] |> html_attributes
    children = parts["tail"] |> String.lstrip |> inline_children

    {tag, attributes: basics ++ additional, children: children}
  end

  defp parse_tag(input) do
      tag = case Regex.run(~r/^([\w]*)[:#.]?/, input) do
              [_, ""] -> :div
              [_, tag] -> String.to_atom(tag)
            end

    {tag, css_classes(input) ++ html_id(input)}
  end

  defp strip_line(line) do
    orig_len = String.length(line)
    trimmed  = String.lstrip(line)
    trim_len = String.length(trimmed)

    {orig_len - trim_len, trimmed}
  end
end
