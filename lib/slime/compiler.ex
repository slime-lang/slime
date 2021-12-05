defmodule Slime.Compiler do
  @moduledoc """
  Compile a tree of parsed Slime into EEx.
  """

  alias Slime.Doctype

  alias Slime.Parser.Nodes.{DoctypeNode, EExNode, HEExNode, HTMLCommentNode, HTMLNode, InlineHTMLNode, VerbatimTextNode}

  alias Slime.TemplateSyntaxError

  @eex_delimiters {"#" <> "{", "}"}
  @heex_delimiters {"{", "}"}

  @void_elements ~w(
    area br col doctype embed hr img input link meta base param
    keygen source menuitem track wbr
  )

  def eex_delimiters, do: @eex_delimiters
  def heex_delimiters, do: @heex_delimiters

  def compile([], _delimiters), do: ""

  def compile(tags, delimiters) when is_list(tags) do
    tags
    |> Enum.map(&compile(&1, delimiters))
    |> Enum.join()
    |> String.replace("\r", "")
  end

  def compile(%DoctypeNode{name: name}, _delimiters), do: Doctype.for(name)
  def compile(%VerbatimTextNode{content: content}, delimiters), do: compile(content, delimiters)

  def compile(%HEExNode{}, @eex_delimiters) do
    # Raise an error if the user generates a HEEx node (by using a :) but the target is EEx

    raise TemplateSyntaxError,
      line: 0,
      message: "I found a HEEx component, but this is not compiling to a HEEx file",
      line_number: 0,
      column: 0
  end

  def compile(%HEExNode{} = tag, @heex_delimiters) do
    # Pass the HEExNode through to HTMLNode since it behaves identically
    tag = Map.put(tag, :__struct__, HTMLNode)
    compile(tag, @heex_delimiters)
  end

  def compile(%HTMLNode{name: name, spaces: spaces} = tag, delimiters) do
    attrs = Enum.map(tag.attributes, &render_attribute(&1, delimiters))
    tag_head = Enum.join([name | attrs])

    body =
      cond do
        tag.closed ->
          "<" <> tag_head <> "/>"

        name in @void_elements ->
          "<" <> tag_head <> ">"

        :otherwise ->
          "<" <> tag_head <> ">" <> compile(tag.children, delimiters) <> "</" <> name <> ">"
      end

    leading_space(spaces) <> body <> trailing_space(spaces)
  end

  def compile(%EExNode{content: code, spaces: spaces, output: output} = eex, delimiters) do
    code = if eex.safe?, do: "{:safe, " <> code <> "}", else: code
    opening = if(output, do: "<%= ", else: "<% ") <> code <> " %>"

    closing =
      if Regex.match?(~r/(fn.*->| do)\s*$/, code) do
        "<% end %>"
      else
        ""
      end

    body = opening <> compile(eex.children, delimiters) <> closing

    leading_space(spaces) <> body <> trailing_space(spaces)
  end

  def compile(%InlineHTMLNode{content: content, children: children}, delimiters) do
    compile(content, delimiters) <> compile(children, delimiters)
  end

  def compile(%HTMLCommentNode{content: content}, delimiters) do
    "<!--" <> compile(content, delimiters) <> "-->"
  end

  def compile({:eex, eex}, _delimiter), do: "<%= " <> eex <> "%>"
  def compile({:safe_eex, eex}, _delimiter), do: "<%= {:safe, " <> eex <> "} %>"
  def compile(raw, _delimiter), do: raw

  @spec hide_dialyzer_spec(any) :: any
  def hide_dialyzer_spec(input), do: input

  defp render_attribute({_, []}, _delimiters), do: ""
  defp render_attribute({_, ""}, _delimiters), do: ""

  defp render_attribute({name, {safe_eex, content}}, delimiters) do
    case content do
      "true" ->
        " #{name}"

      "false" ->
        ""

      "nil" ->
        ""

      _ ->
        {:ok, quoted_content} = Code.string_to_quoted(content)
        render_attribute_code(name, content, quoted_content, safe_eex, delimiters)
    end
  end

  defp render_attribute({name, value}, _delimiters) do
    if value == true do
      " #{name}"
    else
      value =
        cond do
          is_binary(value) -> value
          is_list(value) -> Enum.join(value, " ")
          true -> value
        end

      ~s( #{name}="#{value}")
    end
  end

  defp render_attribute_code(name, _content, quoted, _safe, _delimiters)
       when is_number(quoted) or is_atom(quoted) do
    ~s[ #{name}="#{quoted}"]
  end

  defp render_attribute_code(name, _content, quoted, _, _delimiters) when is_list(quoted) do
    quoted |> Enum.map_join(" ", &Kernel.to_string/1) |> (&~s[ #{name}="#{&1}"]).()
  end

  defp render_attribute_code(name, _content, quoted, :eex, _delimiters) when is_binary(quoted),
    do: ~s[ #{name}="#{quoted}"]

  defp render_attribute_code(name, _content, quoted, _, _delimiters) when is_binary(quoted),
    do: ~s[ #{name}="<%= {:safe, "#{quoted}"} %>"]

  # # Topher and Jonathan are writing elixir here
  # defp render_attribute_code(name, content, {op, _, _}, _delimiters) when op in [:<<>>, :<>] do
  #   # was: ~s[ #{name}="<%= #{content} %>"]
  #   IO.inspect("WE DID IT!")
  #   ~s[ #{name}="{#{content}}"]
  # end

  # NOTE: string with interpolation or strings concatination
  defp render_attribute_code(name, content, {op, _, _}, safe, @heex_delimiters) when op in [:<<>>, :<>] do
    # IO.inspect op, label: "heex_delimiters <<>>"
    expression = if safe == :eex, do: content, else: "{:safe, #{content}}"
    ~s[ #{name}={#{expression}}]
  end

  defp render_attribute_code(name, content, {op, _, _}, safe, @eex_delimiters) when op in [:<<>>, :<>] do
    # IO.inspect op, label: "eex_delimiters <<>>"
    expression = if safe == :eex, do: content, else: "{:safe, #{content}}"
    ~s[ #{name}="<%= #{expression} %>"]
  end

  defp render_attribute_code(name, content, _, safe, @eex_delimiters) do
    # IO.inspect "EEx"

    # When rendering to traditional EEx
    value = if safe == :eex, do: "slim__v", else: "{:safe, slim__v}"

    """
    <% slim__k = "#{name}"; slim__v = Slime.Compiler.hide_dialyzer_spec(#{content}) %>\
    <%= if slim__v do %> <%= slim__k %><%= unless slim__v == true do %>\
    ="<%= #{value} %>"<% end %><% end %>\
    """
  end

  defp render_attribute_code(name, content, _, _safe, @heex_delimiters) do
    # When rendering to html-aware HEEx
    ~s[ #{name}={#{content}}]
  end

  defp leading_space(%{leading: true}), do: " "
  defp leading_space(_), do: ""

  defp trailing_space(%{trailing: true}), do: " "
  defp trailing_space(_), do: ""
end
