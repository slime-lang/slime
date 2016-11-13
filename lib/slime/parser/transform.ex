defmodule Slime.Parser.Transform do
  @moduledoc """
  PEG parser callbacks module.
  Define transformations from parsed iolist to ast.
  See https://github.com/seancribbs/neotoma/wiki#working-with-the-ast
  """

  import Slime.Parser.Preprocessor, only: [indent_size: 1]

  @default_tag Application.get_env(:slime, :default_tag, "div")
  @sort_attrs Application.get_env(:slime, :sort_attrs, true)
  @merge_attrs Application.get_env(:slime, :merge_attrs, %{"class" => " "})
  @shortcut Application.get_env(:slime, :shortcut, %{
    "." => %{attr: "class"},
    "#" => %{attr: "id"}
  })

  # TODO: separate dynamic elixir blocks by parser
  @quote_outside_interpolation_regex ~r/(^|\G)(?:\\.|[^#]|#(?!\{)|(?<pn>#\{(?:[^"}]++|"(?:\\.|[^"#]|#(?!\{)|(?&pn))*")*\}))*?\K"/u

  @type ast :: term
  @type index :: {{:line, non_neg_integer}, {:column, non_neg_integer}}

  @spec transform(atom, iolist, index) :: ast
  def transform(:document, node, _index) do
    case node do
      [[], tags | _] -> tags
      [doctype, [""] | _] -> [doctype]
      [doctype, tags | _] -> [doctype | tags]
    end
  end

  def transform(:doctype, [indent, _, _, type, _], _index) do
    {indent_size(indent),
      {:doctype, Slime.Doctype.for(to_string(type))}
    }
  end

  def transform(:tags_list, node, _index) do
    [tag, rest] = node
    tags = [tag | Enum.flat_map(rest, fn (tag_line) ->
      {indent, _} = tag_line[:tag]
      tag_line[:empty_lines]
      |> Enum.map(fn (_) -> {indent, ""} end)
      |> Enum.concat([tag_line[:tag]])
    end)]

    if Application.get_env(:slime, :keep_lines, false) do
      fix_indents(tags)
    else
      remove_empty_lines(tags)
    end
  end

  def transform(:tag, {:blank, _}, _index), do: {0, ""}
  def transform(:tag, node, _index) do
    case node do
      [indent, {:eex, content: content, inline: false} = tag] ->
        indent = indent_size(indent)
        # TODO: handle if/unless with else in grammar
        if content =~ ~r/^\s*else\s*$/ do
          {indent + 2, tag}
        else
          {indent, tag}
        end
      [indent, tag] -> {indent_size(indent), tag}
      _ -> node
    end
  end

  def transform(:html_comment, node, _index) do
    {:html_comment, children: [to_string(Enum.at(node, 2))]}
  end

  def transform(:ie_comment, node, _index) do
    {:ie_comment,
      content: to_string(node[:condition]),
      children: [to_string(node[:content])]
    }
  end

  def transform(:code_comment, _node, _index), do: ""

  def transform(:verbatim_text, node, _index) do
    indent = indent_size(node[:indent])
    relative_text_indent = indent_size(node[:space])
    text_indent = indent + relative_text_indent + String.length(node[:type])
    [{first_line, is_eex_line} | rest] = node[:content]
    text_indent = text_indent + if first_line == "" && relative_text_indent == 0, do: 1, else: 0
    content = [{text_indent, first_line, is_eex_line} | rest]
    shift_indent = content |> Enum.map(&elem(&1, 0)) |> Enum.min
    shift_indent = if text_indent == shift_indent do
      relative_text_indent = if relative_text_indent == 0, do: 0, else: relative_text_indent - 1
      text_indent - relative_text_indent
    else
      shift_indent
    end
    {content, is_eex} = Enum.reduce(content, {"", false},
      fn ({line_indent, line, is_eex_line}, {result, is_eex}) ->
        result = if result == "", do: result, else: result <> "\n"
        result_line_indent = String.duplicate(" ", line_indent - shift_indent)
        {
          result <> result_line_indent <> line,
          is_eex || is_eex_line
        }
      end
    )

    content = if node[:type] == "'", do: content <> " ", else: content
    content = if is_eex do
      {:eex, content: wrap_in_quotes(content), inline: true}
    else
      content
    end
    {indent, content}
  end

  def transform(:verbatim_text_lines, node, _index) do
    case node do
      [line, []] -> [line]
      [line, nested_lines] ->
        lines = nested_lines[:lines]
        spaces = indent_size(nested_lines[:space])
        [{first_line, is_eex} | rest] = lines
        [line, {spaces, first_line, is_eex} | rest]
    end
  end

  def transform(:verbatim_text_nested_lines, node, _index) do
    case node do
      [line, []] -> [line]
      [line, lines] ->
        lines = Enum.flat_map(lines, fn ([_, line]) ->
          [{first_line, is_eex} | rest] = line[:lines]
          [{indent_size(line[:space]), first_line, is_eex} | rest]
        end)
        [line | lines]
    end
  end

  def transform(:verbatim_text_line, node, _index) do
    case node do
      "" -> {"", false}
      {:simple, content} -> {to_string(content), false}
      {:dynamic, content} -> {to_string(content), true}
    end
  end

  def transform(:embedded_engine, [engine, _, lines], _index) do
    lines = case lines do
      {:empty, _} -> [""]
      lines -> lines |> Enum.map(&(&1[:lines])) |> List.flatten
    end
    result = Slime.Parser.EmbeddedEngine.render_with_engine(engine, lines)
    result
  end

  def transform(:embedded_engine_lines, node, _index) do
    [line, rest] = node
    lines = Enum.map(rest, fn
      ([_, {:lines, lines}]) -> lines
      ([_, lines]) -> lines[:lines]
    end)
    [line | lines]
  end

  def transform(:embedded_engine_line, node, _index) do
    to_string(node)
  end

  def transform(:inline_html, [_, node], _index), do: node

  def transform(:code, node, _index) do
    code = node[:code]
    inline = case node[:inline] do
      "-" -> false
      ["=", _] -> true
    end

    {:eex, content: code, inline: inline}
  end

  def transform(:code_lines, node, _index) do
    case node do
      [code_line, crlf, [_, lines, _]] -> code_line <> crlf <> lines
      [code_line, crlf, line] -> code_line <> crlf <> line
      line -> line
    end
  end

  def transform(:code_line, node, _index) do
    node |> to_string |> String.replace("\x0E", "")
  end

  def transform(:code_line_with_brake, node, _index) do
    node |> to_string |> String.replace("\x0E", "")
  end

  def transform(:inline_tag, node, _index) do
    {tag_name, initial_attrs} = node[:tag]
    {tag_name, [
      {:attributes, initial_attrs},
      {:children, [node[:children]]}
    ]}
  end

  def transform(:simple_tag, node, _index) do
    {tag_name, initial_attrs} = node[:tag]
    attrs = case node[:attrs] do
      [] -> []
      [_space, attrs_list] -> attrs_list
    end

    content = case node[:content] do
      [] -> [{:close, false}]
      [_, "/"] -> [{:close, true}]
      [_, child] -> [{:children, [child]}, {:close, false}]
    end

    attributes =
      initial_attrs
      |> Enum.concat(attrs)
      |> Slime.Parser.AttributesKeyword.merge(@merge_attrs)

    attributes = if @sort_attrs do
      Enum.sort_by(attributes, fn ({key, _value}) -> key end)
    else
      attributes
    end

    {tag_name, [
      {:attributes, attributes},
      {:spaces, node[:spaces]} |
      content
    ]}
  end

  def transform(:text_content, node, _index) do
    case node do
      {:dynamic, content} ->
        {:eex, content: content |> to_string |> wrap_in_quotes, inline: true}
      {:simple, content} -> content
    end
  end

  def transform(:dynamic_content, node, _index) do
    content = node |> Enum.at(3) |> to_string
    {:eex, content: content, inline: true}
  end

  def transform(:tag_spaces, node, _index) do
    leading = node[:leading]
    trailing = node[:trailing]
    case {leading, trailing} do
      {"<", ">"} ->  %{leading: true, trailing: true}
      {"<", _} ->  %{leading: true}
      {_, ">"} ->  %{trailing: true}
      _ -> %{}
    end
  end

  def transform(:tag_shortcut, node, _index) do
    {tag, attrs} = case node do
      {:tag, value} -> {value, []}
      {:attrs, value} -> {@default_tag, value}
      list -> {list[:tag], list[:attrs]}
    end
    {tag_name, initial_attrs} = expand_tag_shortcut(tag)
    {tag_name, Enum.concat(initial_attrs, attrs)}
  end

  def transform(:shortcuts, node, _index) do
    Enum.concat([node[:head] | node[:tail]])
  end

  def transform(:shortcut, node, _index) do
    {nil, attrs} = expand_attr_shortcut(node[:type], node[:value])
    attrs
  end

  def transform(:wrapped_attributes, node, _index), do: Enum.at(node, 1)

  def transform(:wrapped_attributes_list, node, _index) do
    head = node[:head]
    tail = Enum.map(node[:tail] || [[]], &List.last/1)
    [head | tail]
  end

  def transform(:wrapped_attribute, node, _index) do
    case node do
      {:attribute, attr} -> attr
      {:attribute_name, name} -> {name, true}
    end
  end

  def transform(:plain_attributes, node, _index) do
    head = node[:head]
    tail = Enum.map(node[:tail] || [[]], &List.last/1)
    [head | tail]
  end

  def transform(:attribute, [name, _, value], _index), do: {name, value}

  def transform(:attribute_value, node, _index) do
    case node do
      {:simple, [_, content, _]} -> to_string(content)
      {:dynamic, content} -> {:eex, content: to_string(content), inline: true}
    end
  end

  def transform(:text, node, _index), do: to_string(node)
  def transform(:tag_name, node, _index), do: to_string(node)
  def transform(:attribute_name, node, _index), do: to_string(node)
  def transform(:crlf, node, _index), do: to_string(node)
  def transform(_symdol, node, _index), do: node

  defp fix_indents(lines), do: lines |> Enum.reverse |> fix_indents(0, [])
  defp fix_indents([], _, result), do: result
  defp fix_indents([{0, ""} | rest], current, result) do
    fix_indents(rest, current, [{current, ""} | result])
  end
  defp fix_indents([{indent, _} = line | rest], current, result) do
    fix_indents(rest, indent, [line | result])
  end

  def remove_empty_lines(lines) do
    Enum.filter(lines, fn
      ({0, ""}) -> false
      (_) -> true
    end)
  end

  def expand_tag_shortcut(tag) do
    case Dict.fetch(@shortcut, tag) do
      :error -> {tag, []}
      {:ok, spec} -> expand_shortcut(spec, tag)
    end
  end

  defp expand_attr_shortcut(type, value) do
    spec = Dict.fetch!(@shortcut, type)
    expand_shortcut(spec, value)
  end

  def expand_shortcut(spec, value) do
    attrs = case spec[:attr] do
      nil -> []
      attr_names -> attr_names |> List.wrap |> Enum.map(&{&1, value})
    end

    final_attrs = Enum.concat(attrs, Dict.get(spec, :additional_attrs, []))
    {spec[:tag], final_attrs}
  end

  defp wrap_in_quotes(content) do
    ~s("#{String.replace(content, @quote_outside_interpolation_regex, ~S(\\"))}")
  end
end
