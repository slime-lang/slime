defmodule Slime.Compiler do
  @moduledoc """
  Compile a tree of parsed Slime into EEx.
  """

  alias Slime.Doctype

  alias Slime.Parser.Nodes.HTMLNode
  alias Slime.Parser.Nodes.EExNode
  alias Slime.Parser.Nodes.VerbatimTextNode
  alias Slime.Parser.Nodes.HTMLCommentNode
  alias Slime.Parser.Nodes.InlineHTMLNode
  alias Slime.Parser.Nodes.DoctypeNode

  @void_elements ~w(
    area br col doctype embed hr img input link meta base param
    keygen source menuitem track wbr
  )

  def compile([]), do: ""
  def compile(tags) when is_list(tags) do
    tags
    |> Enum.map(&compile(&1))
    |> Enum.join
    |> String.replace("\r", "")
  end
  def compile(%DoctypeNode{name: name}), do: Doctype.for(name)
  def compile(%VerbatimTextNode{content: content}), do: compile(content)
  def compile(%HTMLNode{name: name, spaces: spaces} = tag) do
    attrs = Enum.map(tag.attributes, &render_attribute/1)
    tag_head = Enum.join([name | attrs])

    body = cond do
      tag.closed             -> "<" <> tag_head <> "/>"
      name in @void_elements -> "<" <> tag_head <> ">"
      :otherwise             ->
        "<" <> tag_head <> ">" <> compile(tag.children) <> "</" <> name <> ">"
    end

    leading_space(spaces) <> body <> trailing_space(spaces)
  end
  def compile(%EExNode{content: code, spaces: spaces, output: output} = eex) do
    code = if eex.safe?, do: "{:safe, " <> code <> "}", else: code
    opening = (if output, do: "<%= ", else: "<% ") <> code <> " %>"
    closing = if Regex.match?(~r/(fn.*->| do)\s*$/, code) do
      "<% end %>"
    else
      ""
    end
    body = opening <> compile(eex.children) <> closing

    leading_space(spaces) <> body <> trailing_space(spaces)
  end
  def compile(%InlineHTMLNode{content: content, children: children}) do
    compile(content) <> compile(children)
  end
  def compile(%HTMLCommentNode{content: content}) do
    "<!--" <> compile(content) <> "-->"
  end
  def compile({:eex, eex}), do: "<%= " <> eex <> "%>"
  def compile({:safe_eex, eex}), do: "<%= {:safe, " <> eex <> "} %>"
  def compile(raw), do: raw

  @spec hide_dialyzer_spec(any) :: any
  def hide_dialyzer_spec(input), do: input

  defp render_attribute({_, []}), do: ""
  defp render_attribute({_, ""}), do: ""
  defp render_attribute({name, {safe_eex, content}}) do
    case content do
      "true"  -> " #{name}"
      "false" -> ""
      "nil"   -> ""
      _ ->
        {:ok, quoted_content} = Code.string_to_quoted(content)
        render_attribute_code(name, content, quoted_content, safe_eex)
    end
  end
  defp render_attribute({name, value}) do
    if value == true do
      " #{name}"
    else
      value = cond do
        is_binary(value) -> value
        is_list(value) -> Enum.join(value, " ")
        true -> value
      end

      ~s( #{name}="#{value}")
    end
  end

  defp render_attribute_code(name, _content, quoted, _safe)
      when is_number(quoted) or is_atom(quoted) do
    ~s[ #{name}="#{quoted}"]
  end

  defp render_attribute_code(name, _cotnent, quoted, safe) when is_binary(quoted) do
    value = if :eex == safe, do: quoted, else: ~s[<%= {:safe, "#{quoted}"} %>]
    ~s[ #{name}="#{value}"]
  end

  # NOTE: string with interpolation or strings concatination
  defp render_attribute_code(name, content, {op, _, _}, safe) when op in [:<<>>, :<>] do
    value = if safe == :eex, do: content, else: "{:safe, #{content}}"
    ~s[ #{name}="<%= #{value} %>"]
  end

  defp render_attribute_code(name, content, _, safe) do
    value = if safe == :eex, do: "slim__v", else: "{:safe, slim__v}"
    """
    <% slim__k = "#{name}"; slim__v = Slime.Compiler.hide_dialyzer_spec(#{content}) %>\
    <%= if slim__v do %> <%= slim__k %><%= unless slim__v == true do %>\
    ="<%= #{value} %>"<% end %><% end %>\
    """
  end

  defp leading_space(%{leading: true}), do: " "
  defp leading_space(_), do: ""

  defp trailing_space(%{trailing: true}), do: " "
  defp trailing_space(_), do: ""
end
