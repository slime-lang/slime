defmodule SlimFast.Parser do
  @blank    ""
  @content  "|"
  @html     "<"
  @preserved"'"
  @script   "-"
  @smart    "="

  @doctypes [
    "1.1":            "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">",
    "5":              "<!DOCTYPE html>",
    "basic":          "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML Basic 1.1//EN\" \"http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd\">",
    "frameset":       "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Frameset//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">",
    "html":           "<!DOCTYPE html>",
    "mobile":         "<!DOCTYPE html PUBLIC \"-//WAPFORUM//DTD XHTML Mobile 1.2//EN\" \"http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd\">",
    "strict":         "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">",
    "transitional":   "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">",
    "xml ISO-8859-1": "<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>",
    "xml":            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"]

  def parse_lines([]), do: []
  def parse_lines([h|t]), do: [parse_line(h)|parse_lines(t)] |> Enum.reject(&is_nil/1)

  def parse_line(@blank), do: nil
  def parse_line(line) do
    {indentation, line} = strip_line(line)

    line = line
           |> String.first
           |> parse_line(line)

    {indentation, line}
  end

  defp attribute_val("\"" <> value), do: String.slice(value, 0..-2)
  defp attribute_val(value), do: parse_eex(value, true)

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
  defp inline_children("=" <> content), do: [parse_eex(content, true)]
  defp inline_children(input), do: [String.strip(input, ?")]

  defp parse_eex(input, inline \\ false) do
    input = String.lstrip(input)
    script = input
             |> String.split(~r/^[-|=|==]/)
             |> List.last
             |> String.lstrip
    inline = inline or String.starts_with?(input, "=")
    {:eex, content: script, inline: inline}
  end

  defp parse_eex_string(input) do
    if String.contains?(input, "\#{") do
      {:eex, content: "\"#{input |> String.replace("\"", "\\\"")}\"", inline: true}
    else
      input
    end
  end

  defp parse_line(@blank, _line), do: @blank
  defp parse_line(@content, line), do: line |> String.slice(1..-1) |> String.strip
  defp parse_line(@html, line), do: line |> String.strip |> parse_eex_string
  defp parse_line(@preserved, line), do: line |> String.slice(1..-1)
  defp parse_line(@script, line), do: parse_eex(line)
  defp parse_line(@smart, line), do: parse_eex(line, true)

  defp parse_line(_, "doctype " <> type) do
    key = String.to_atom(type)
    {:doctype, Keyword.get(@doctypes, key)}
  end

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
    line = String.replace(line, ~r/\t/, "  ")

    orig_len = String.length(line)
    trimmed  = String.lstrip(line)
    trim_len = String.length(trimmed)

    {orig_len - trim_len, trimmed}
  end
end
