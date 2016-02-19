defmodule Slime.Tree do
  @moduledoc """
  Build a tree from a series of Slime lines.
  """

  alias Slime.Tree.DoctypeNode
  alias Slime.Tree.EExNode
  alias Slime.Tree.HTMLNode
  alias Slime.Tree.TextNode

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
    split_children? = existing == [] && children != [] &&
      Application.get_env(:slime, :keep_lines)
    sep = if split_children?, do: [%TextNode{content: ""}], else: []
    children_tree   = existing ++ sep ++ build_tree(children)
    attrs           = Keyword.put(attrs, :children, children_tree)
    branch          = to_branch({tag, attrs})
    tree            = build_tree(rem)
    [branch|tree]
  end


  defp make_child_filter(parent_indentation) do
    fn
      {:prev, _} -> true
      {indent, _} -> indent > parent_indentation
      _           -> true
    end
  end

  defp to_branch(%{} = branch), do: branch
  defp to_branch(text) when is_binary(text) do
    %TextNode{content: text}
  end
  defp to_branch({:doctype, doc_string}) do
    %DoctypeNode{content: doc_string}
  end
  defp to_branch({:eex, attrs}) do
    children = Keyword.get(attrs, :children, [])
    inline = Keyword.get(attrs, :inline, false)
    %EExNode{
      attributes: [inline: inline],
      children: children,
      content: attrs[:content]
    }
  end
  defp to_branch({tag, attrs}) do
    children = attrs |> Keyword.get(:children, []) |> Enum.map(&to_branch/1)
    Enum.reduce(
      attrs,
      %HTMLNode{tag: tag, children: children},
      fn
        ({:children, _}, branch) -> branch
        ({k, v}, branch) -> Map.put(branch, k, v)
      end
    )
  end
end
