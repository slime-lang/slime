defmodule SlimFast.Parser do
  alias SlimFast.Parser.AttributesKeyword

  @blank    ""
  @content  "|"
  @comment  "/"
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

  @tabsize 2
  @soft_tab String.duplicate(" ", @tabsize)

  @merge_attrs %{class: " "}

  def parse_lines(lines) do
    parse_lines(Enum.map(lines, &use_soft_tabs/1), [])
  end

  defp parse_lines([], result), do: Enum.reverse(result)
  defp parse_lines([head | tail], result) do
    case parse_verbatim_text(head, tail) do
      {text, rest} -> parse_lines(rest, [text | result])
      nil ->
        case parse_line(head) do
          nil -> parse_lines(tail, result)
          line -> parse_lines(tail, [line | result])
        end
    end
  end

  @verbatim_text_regex ~r/^(\s*)([#{@content}#{@preserved}])\s?/
  defp parse_verbatim_text(head, tail) do
    case Regex.run(@verbatim_text_regex, head) do
      nil -> nil
      [text_indent, indent, text_type] ->
        indent = String.length(indent)
        text_indent = String.length(text_indent)
        {text_lines, rest} = parse_verbatim_text(indent, text_indent, head, tail)
        text = Enum.join(text_lines, "\n")
        if text_type == @preserved, do: text = text <> " "
        {{indent, parse_eex_string(text)}, rest}
    end
  end

  defp parse_verbatim_text(indent, text_indent, head, tail) do
    if String.length(head) == text_indent, do: text_indent = text_indent + 1
    {_, head_text} = String.split_at(head, text_indent)
    {text_lines, rest} = Enum.split_while(tail, fn (line) ->
      {line_indent, _} = strip_line(line)
      indent < line_indent
    end)
    text_lines = Enum.map(text_lines, fn (line) ->
      {_, text} = String.split_at(line, text_indent)
      text
    end)
    unless head_text == "", do: text_lines = [head_text | text_lines]
    {text_lines, rest}
  end

  def parse_line(@blank), do: nil
  def parse_line(line) do
    {indentation, line} = strip_line(line)

    line = line
           |> String.first
           |> parse_line(line)

    {indentation, line}
  end

  defp attribute_val("\"" <> value), do: String.slice(value, 0..-2) |> parse_eex_string
  defp attribute_val(value), do: parse_eex(value, true)

  defp css_classes(input) do
    css = ~r/\.([\w-]+)/
          |> Regex.scan(input)
          |> Enum.flat_map(fn ([_|class]) -> class end)

    cond do
      length(css) > 0 -> [class: css]
      true -> []
    end
  end

  defp html_attribute(attribute) do
    [key, value] = attribute |> String.split("=", parts: 2)
    key = key
          |> String.strip
          |> String.to_atom

    value = value
            |> String.strip
            |> attribute_val

    {key, value}
  end

  defp html_attributes(input) do
    ~r/[\w-]+\s*=\s*(".+?"|\w+)/
    |> Regex.scan(input)
    |> Enum.reduce([], fn ([h|_], acc) -> [html_attribute(h)|acc] end)
  end

  defp html_id(input) do
    case Regex.run(~r/#([\w-]{1,})/, input) do
      [_, id] -> [id: id]
      _ -> []
    end
  end

  defp inline_children(@blank), do: []
  defp inline_children("=" <> content), do: [parse_eex(content, true)]
  defp inline_children(input), do: [String.strip(input, ?") |> parse_eex_string]

  defp parse_comment("!" <> comment), do: {:html_comment, children: [String.strip(comment)]}
  defp parse_comment("[" <> comment) do
    [h|[t|_]] = comment |> String.split("]", parts: 2)
    conditions = String.strip(h)
    children = t |> String.strip |> inline_children
    {:ie_comment, content: conditions, children: children}
  end
  defp parse_comment(_comment), do: ""

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
      script = "\"#{String.replace(input, "\"", "\\\"")}\""
      {:eex, content: script, inline: true}
    else
      input
    end
  end

  defp parse_line(@blank, _line), do: @blank
  defp parse_line(@content, line), do: line |> String.slice(1..-1) |> String.strip |> parse_eex_string
  defp parse_line(@comment, line), do: line |> String.slice(1..-1) |> parse_comment
  defp parse_line(@html, line), do: line |> String.strip |> parse_eex_string
  defp parse_line(@preserved, line), do: line |> String.slice(1..-1) |> parse_eex_string
  defp parse_line(@script, line), do: parse_eex(line)
  defp parse_line(@smart, line), do: parse_eex(line, true)

  defp parse_line(_, "doctype " <> type) do
    key = String.to_atom(type)
    {:doctype, Keyword.get(@doctypes, key)}
  end

  defp parse_line(_, line) do
    parts = ~r/^\s*(?<tag>\w*(?:[#.][\w-]+)*)(?<attrs>(?:\s*[\w-]+\s*=(".+"|\w+))*)(?<tail>.*)/
            |> Regex.named_captures(line)

    {tag, basics} = parse_tag(line)

    additional = parts["attrs"] |> html_attributes
    children = parts["tail"] |> String.lstrip |> inline_children
    attributes = AttributesKeyword.merge(basics ++ additional, @merge_attrs)

    {tag, attributes: attributes, children: children}
  end

  defp parse_tag(input) do
    [input | _] = String.split(input, " ", parts: 2)
    tag = case Regex.run(~r/^(\w*)[:#\.]?/, input) do
            [_, ""] -> :div
            [_, tag] -> String.to_atom(tag)
          end

    {tag, css_classes(input) ++ html_id(input)}
  end

  defp use_soft_tabs(line) do
    String.replace(line, ~r/\t/, @soft_tab)
  end

  defp strip_line(line) do
    orig_len = String.length(line)
    trimmed  = String.lstrip(line)
    trim_len = String.length(trimmed)

    {orig_len - trim_len, trimmed}
  end
end
