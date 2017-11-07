defmodule Slime.Parser.Transform do
  @moduledoc """
  PEG parser callbacks module.
  Define transformations from parsed iolist to ast.
  See https://github.com/seancribbs/neotoma/wiki#working-with-the-ast
  """

  import Slime.Parser.Preprocessor, only: [indent_size: 1]
  alias Slime.Parser.AttributesKeyword
  alias Slime.Parser.EmbeddedEngine
  alias Slime.Parser.TextBlock

  alias Slime.Parser.Nodes.HTMLNode
  alias Slime.Parser.Nodes.EExNode
  alias Slime.Parser.Nodes.VerbatimTextNode
  alias Slime.Parser.Nodes.HTMLCommentNode
  alias Slime.Parser.Nodes.InlineHTMLNode
  alias Slime.Parser.Nodes.DoctypeNode

  alias Slime.TemplateSyntaxError

  @merge_attrs %{"class" => " "}
  @default_tag "div"
  @sort_attrs true
  @shortcut %{
    "." => %{attr: "class"},
    "#" => %{attr: "id"}
  }

  @type ast :: term
  @type index :: {{:line, non_neg_integer}, {:column, non_neg_integer}}

  @spec transform(atom, iolist, index) :: ast
  def transform(:document, input, _index) do
    case input do
      [_blank_lines, [], tags | _] -> tags
      [_blank_lines, doctype, [""] | _] -> [doctype]
      [_blank_lines, doctype, tags | _] -> [doctype | tags]
    end
  end

  def transform(:doctype, input, _index) do
    %DoctypeNode{name: to_string(input[:name])}
  end

  def transform(:tag, [tag, _], _index), do: tag
  def transform(:tag_item, [_, tag], _index), do: tag

  def transform(:tags, input, _index) do
    Enum.flat_map(input, fn ([tag, crlfs]) -> [tag | newlines(crlfs)] end)
  end

  def transform(:nested_tags, [crlfs, _, children, _], _index) do
    newlines(crlfs) ++ children
  end

  def transform(:slime_tag, [tag, spaces, _, content], _index) do
    {name, shorthand_attrs} = tag
    {attrs, children, is_closed} = content

    merge_attrs = Application.get_env(:slime, :merge_attrs, @merge_attrs)

    attributes =
      shorthand_attrs
      |> Enum.concat(attrs)
      |> AttributesKeyword.merge(merge_attrs)

    attributes = if Application.get_env(:slime, :sort_attrs, @sort_attrs) do
      Enum.sort_by(attributes, fn ({key, _value}) -> key end)
    else
      attributes
    end

    %HTMLNode{name: name, attributes: attributes, spaces: spaces,
      closed: is_closed, children: children}
  end

  def transform(:tag_attributes_and_content, input, _index) do
    case input do
      [attrs, _, {children, is_closed}] -> {attrs, children, is_closed}
      [_, {children, is_closed}] -> {[], children, is_closed}
    end
  end

  def transform(:tag_content, input, _index) do
    case input do
      "/" -> {[], true}
      "" -> {[], false}
      [] -> {[], false}
      other when is_list(other) -> {other, false}
      _ -> {[input], false}
    end
  end

  def transform(:inline_tag, [_, _, tag], _index), do: tag

  def transform(:inline_text, [_, text], _index) do
    %VerbatimTextNode{
      content: TextBlock.render_without_indentation(text)}
  end

  def transform(:text_item, input, _index) do
    case input do
      {:dynamic, {:safe, expression}} -> {:safe_eex, expression}
      {:dynamic, expression} -> {:eex, expression}
      {:static, text} -> to_string(text)
    end
  end

  def transform(:interpolation, [_, expression, _], _index) do
    to_string(expression)
  end

  def transform(:safe_interpolation, [_, expression, _], _index) do
    to_string(expression)
  end

  def transform(:html_comment, input, _index) do
    indent = indent_size(input[:indent])
    decl_indent = indent + String.length(input[:type])

    %HTMLCommentNode{
      content: TextBlock.render_content(input[:content], decl_indent)}
  end

  def transform(:code_comment, _input, _index), do: ""

  def transform(:verbatim_text, input, _index) do
    indent = indent_size(input[:indent])
    decl_indent = indent + String.length(input[:type])
    content = TextBlock.render_content(input[:content], decl_indent)
    content = if input[:type] == "'", do: content ++ [" "], else: content

    %VerbatimTextNode{content: content}
  end

  def transform(:text_block, input, _index) do
    case input do
      [line, []] -> [line]
      [line, nested_lines] -> [line | nested_lines[:lines]]
    end
  end

  def transform(:text_block_nested_lines, input, _index) do
    case input do
      [line, []] -> [line]
      [line, nested] ->
        [line | Enum.flat_map(nested, fn([_crlf, nested_line]) ->
          case nested_line do
            {:lines, lines} -> lines
            [_indent, {:lines, lines}, _dedent] -> lines
          end
        end)]
    end
  end

  def transform(:embedded_engine, [engine, _, content], index) do
    case EmbeddedEngine.parse(engine, content[:lines]) do
      {:ok, {tag, content}} ->
        %HTMLNode{name: tag,
          attributes: (content[:attributes] || []),
          children: content[:children]}
      {:ok, content} -> content
      {:error, message} ->
        {{:line, line_number}, {:column, column}} = index
        raise TemplateSyntaxError, message: message,
          line: "", line_number: line_number, column: column
    end
  end

  def transform(:embedded_engine_lines, [first_line, rest], _index) do
    [first_line | Enum.map(rest, fn ([_, lines]) -> lines end)]
  end

  def transform(:indented_text_line, [space, content], _index) do
    {indent_size(space), content}
  end

  def transform(:inline_html, [_, content, children], _index) do
    %InlineHTMLNode{content: content, children: children}
  end

  def transform(:code, input, _index) do
    {output, safe, spaces} = case input[:output] do
      "-" -> {false, false, %{}}
      [_, safe, spaces] -> {true, safe == "=", spaces}
    end

    %EExNode{
      content: input[:code],
      output: output,
      spaces: spaces,
      children: input[:children] ++ input[:optional_else],
      safe?: safe
    }
  end

  def transform(:code_else_condition, input, _index) do
    [%EExNode{content: "else", children: input[:children]}]
  end

  def transform(:code_lines, input, _index) do
    case input do
      [code_line, crlf, line] -> code_line <> crlf <> line
      line -> line
    end
  end

  def transform(:code_line, input, _index), do: to_string(input)
  def transform(:code_line_with_break, input, _index), do: to_string(input)

  def transform(:dynamic_content, [_, safe, _, content], _index) do
    %EExNode{content: to_string(content), output: true, safe?: safe == "="}
  end

  def transform(:tag_spaces, input, _index) do
    leading = input[:leading]
    trailing = input[:trailing]
    case {leading, trailing} do
      {"<", ">"} ->  %{leading: true, trailing: true}
      {"<", _} ->  %{leading: true}
      {_, ">"} ->  %{trailing: true}
      _ -> %{}
    end
  end

  def transform(:tag_shortcut, input, _index) do
    {tag, attrs} = case input do
      {:tag, value} -> {value, []}
      {:attrs, value} ->
        {Application.get_env(:slime, :default_tag, @default_tag), value}
      list -> {list[:tag], list[:attrs]}
    end
    {tag_name, initial_attrs} = expand_tag_shortcut(tag)
    {tag_name, Enum.concat(initial_attrs, attrs)}
  end

  def transform(:shortcuts, input, _index) do
    Enum.concat([input[:head] | input[:tail]])
  end

  def transform(:shortcut, input, _index) do
    {nil, attrs} = expand_attr_shortcut(input[:type], input[:value])
    attrs
  end

  def transform(:wrapped_attributes, [_o, attrs, _c], _index), do: attrs
  def transform(:wrapped_attributes, indented, _index), do: Enum.at(indented, 3)

  def transform(:wrapped_attribute, [_space, attribute], _index) do
    case attribute do
      {:attribute, attr} -> attr
      {:attribute_name, name} -> {name, true}
    end
  end

  def transform(:plain_attributes, input, _index) do
    head = input[:head]
    tail = Enum.map(input[:tail] || [[]], &List.last/1)
    [head | tail]
  end

  def transform(:attribute, [name, _, safe, value], _index) do
    value = if safe == "=" do
      case value do
        {:eex, content} -> {:safe_eex, content}
        _ -> {:safe_eex, ~s["#{value}"]}
      end
    else
      value
    end
    {name, value}
  end

  def transform(:attribute_value, input, _index) do
    case input do
      {:simple, [_, content, _]} -> to_string(content)
      {:dynamic, content} -> {:eex, to_string(content)}
    end
  end

  def transform(:tag_name, input, _index), do: to_string(input)
  def transform(:attribute_name, input, _index), do: to_string(input)
  def transform(:crlf, input, _index), do: to_string(input)
  def transform(_symdol, input, _index), do: input

  def expand_tag_shortcut(tag) do
    shortcut = Application.get_env(:slime, :shortcut, @shortcut)
    case Map.fetch(shortcut, tag) do
      :error -> {tag, []}
      {:ok, spec} -> expand_shortcut(spec, tag)
    end
  end

  defp expand_attr_shortcut(type, value) do
    shortcut = Application.get_env(:slime, :shortcut, @shortcut)
    spec = Map.fetch!(shortcut, type)
    expand_shortcut(spec, value)
  end

  def newlines(crlfs) do
    if Application.get_env(:slime, :keep_lines) do
      Enum.map(crlfs, fn (_) -> %VerbatimTextNode{content: ["\n"]} end)
    else
      []
    end
  end

  def expand_shortcut(spec, value) do
    attrs = case spec[:attr] do
      nil -> []
      attr_names -> attr_names |> List.wrap |> Enum.map(&{&1, value})
    end

    final_attrs = Enum.concat(attrs, Map.get(spec, :additional_attrs, []))
    {spec[:tag], final_attrs}
  end
end
