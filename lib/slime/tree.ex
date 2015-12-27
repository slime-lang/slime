defmodule Slime.Tree do
  @moduledoc """
  Build a tree from a series of Slime lines.
  """

  defmodule Branch do
    @moduledoc "A node in a tree of Slim"
    defstruct attributes: [],
              children: [],
              content: "",
              type: nil,
              spaces: %{},
              close: false
  end

  def build_tree([]), do: []
  def build_tree([{_, line}|t]) when is_binary(line) do
    branch = to_branch(line)
    tree   = build_tree(t)
    [branch|tree]
  end
  def build_tree([{_, {:doctype, _} = line}|t]) do
    branch = to_branch(line)
    tree   = build_tree(t)
    [branch|tree]
  end
  def build_tree([{indentation, {tag, attrs}}|t]) do
    existing =
      attrs
      |> Keyword.get(:children, [])
      |> Enum.map(&to_branch/1)
    filter          = make_child_filter(indentation)
    {children, rem} = Enum.split_while(t, filter)
    children_tree   = existing ++ build_tree(children)
    attrs           = Keyword.put(attrs, :children, children_tree)
    branch          = to_branch({tag, attrs})
    tree            = build_tree(rem)
    [branch|tree]
  end


  defp make_child_filter(parent_indentation) do
    fn
      {indent, _} -> indent > parent_indentation
      _           -> true
    end
  end


  defp to_branch(text) when is_binary(text) do
    %Branch{type: :text, content: text}
  end
  defp to_branch({:doctype, doc_string}) do
    %Branch{type: :doctype, content: doc_string}
  end
  defp to_branch({:eex, attrs}) do
    children = Keyword.get(attrs, :children, [])
    inline = Keyword.get(attrs, :inline, false)
    %Branch{
      type: :eex,
      attributes: [inline: inline],
      children: children,
      content: attrs[:content]
    }
  end
  defp to_branch({type, attrs}) do
    Enum.reduce(
      [type: type] ++ attrs,
      %Branch{},
      fn({k, v}, branch) -> Map.put(branch, k, v) end
    )
  end
end
