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
  def compile(raw), do: raw

  defp render_attribute({_, []}), do: ""
  defp render_attribute({_, ""}), do: ""
  defp render_attribute({name, {:eex, content}}) do
    case content do
      "true"  -> " #{to_string(name)}"
      "false" -> ""
      "nil"   -> ""
      _ ->
       """
       <% slim__k = "#{to_string(name)}"; slim__v = #{content} %>\
       <%= if slim__v do %> <%= slim__k %><%= unless slim__v == true do %>\
       ="<%= slim__v %>"<% end %><% end %>\
       """
    end
  end
  defp render_attribute({name, value}) do
    if value == true do
      " #{to_string(name)}"
    else
      value = cond do
        is_binary(value) -> value
        is_list(value) -> Enum.join(value, " ")
        true -> to_string(value)
      end

      ~s( #{to_string(name)}="#{value}")
    end
  end

  defp leading_space(%{leading: true}), do: " "
  defp leading_space(_), do: ""

  defp trailing_space(%{trailing: true}), do: " "
  defp trailing_space(_), do: ""
end
