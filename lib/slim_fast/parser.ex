defmodule SlimFast.Parser do
  @blank    ""
  @class    "."
  @content  "|"
  @id       "#"
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

  defp css_classes(input) do
    ~r/\.([a-z_-]{1,})/
    |> Regex.scan(input)
    |> Enum.flat_map(fn ([_|class]) -> class end)
  end

  defp html_id(input) do
    case Regex.run(~r/#([a-z_-]{1,})/, input) do
      [_, id] -> id
      nil -> nil
    end
  end

  defp inline_child(_input, nil), do: []
  defp inline_child(input, token) do
    content = String.split(input, token) |> List.last
    child = case token do
              "=" -> parse_eex("- " <> content)
              _   -> parse_text(content)
            end
    [child]
  end

  defp parse_attributes(input) do
    inline = Regex.run(~r/(.){1,2}\s/, input)
    [id: html_id(input), css: css_classes(input), children: inline_child(input, inline)]
  end

  defp parse_div(input) do
    {:div, parse_attributes(input)}
  end

  defp parse_eex(input) do
    script = input
             |> String.slice(2..-1)
             |> String.lstrip
    {:eex, content: script}
  end

  defp parse_line(@blank, _line), do: parse_text
  defp parse_line(@content, line), do: line |> String.slice(2..-1) |> parse_text

  defp parse_line(@class, line), do: parse_div(line)
  defp parse_line(@id, line), do: parse_div(line)

  defp parse_line(@script, line), do: parse_eex(line)
  defp parse_line(@smart, line), do: parse_eex(line)

  defp parse_line(_, line) do
    tag = line |> String.split(~r{[#. ]}) |> List.first |> String.to_atom
    {tag, parse_attributes(line)}
  end

  defp parse_text(input \\ "") do
    {:text, [content: input]}
  end

  defp strip_line(line) do
    orig_len = String.length(line)
    trimmed  = String.lstrip(line)
    trim_len = String.length(trimmed)

    {orig_len - trim_len, trimmed}
  end

end
