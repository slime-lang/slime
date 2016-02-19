defmodule Slime.Compiler do
  @moduledoc """
  Compile a tree of parsed Slime into EEx.
  """

  alias Slime.Tree.DoctypeNode
  alias Slime.Tree.EExNode
  alias Slime.Tree.HTMLNode
  alias Slime.Tree.TextNode

  @void_elements ~w(
    area br col doctype embed hr img input link meta base param
    keygen source menuitem track wbr
  )

  def compile(tree) do
    lines_sep = if Application.get_env(:slime, :keep_lines), do: "\n", else: ""
    tree
    |> Enum.map(fn branch -> render_branch(branch) end)
    |> Enum.join(lines_sep)
    |> String.replace("\r", "")
  end

  defp render_attribute(_, []), do: ""
  defp render_attribute(_, ""), do: ""
  defp render_attribute(name, {:eex, opts}) do
    value = opts[:content]
    case value do
      "true"  -> " #{to_string(name)}"
      "false" -> ""
      "nil"   -> ""
      _ ->
       """
       <% slim__k = "#{to_string(name)}"; slim__v = #{value} %>\
       <%= if slim__v do %> <%= slim__k %><%= unless slim__v == true do %>\
       ="<%= slim__v %>"<% end %><% end %>\
       """
    end
  end
  defp render_attribute(name, value) do
    value = cond do
              is_binary(value) -> value
              is_list(value) -> Enum.join(value, " ")
              true -> to_string(value)
            end

    ~s( #{to_string(name)}="#{value}")
  end

  defp render_branch(%DoctypeNode{content: text}), do: text
  defp render_branch(%TextNode{content: text}),    do: text
  defp render_branch(%{} = branch) do
    opening =
      branch.attributes
      |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
      |> Enum.join
      |> open(branch)
    closing = close(branch)
    opening <> compile(branch.children) <> closing
  end


  defp open(_, %EExNode{content: code, attributes: attrs}) do
    inline = if attrs[:inline], do: "=", else: ""
    "<%#{inline} #{code} %>\r"
  end
  defp open(_, %HTMLNode{tag: :html_comment}) do
    "<!--"
  end
  defp open(_, %HTMLNode{tag: :ie_comment, content: conditions}) do
    "<!--[#{conditions}]>"
  end
  defp open(attrs, %HTMLNode{tag: tag, spaces: spaces, close: close}) do
    prefix = if spaces[:leading], do: " "
    suffix = if close, do: "/"
    tag    = String.rstrip("#{tag}#{attrs}")
    "#{prefix}<#{tag}#{suffix}>"
  end


  defp close(%HTMLNode{tag: tag, spaces: spaces}) when tag in @void_elements do
    if spaces[:trailing] do
      " "
    else
      ""
    end
  end
  defp close(%HTMLNode{tag: :html_comment}) do
    "-->"
  end
  defp close(%HTMLNode{tag: :ie_comment}) do
    "<![endif]-->"
  end
  defp close(%EExNode{content: code}) do
    if Regex.match?(~r/(fn.*->| do)\s*$/, code) do
      "<% end %>"
    else
      ""
    end
  end
  defp close(%HTMLNode{tag: tag, spaces: spaces}) do
    "</#{tag}>#{if spaces[:trailing], do: " "}"
  end
end
