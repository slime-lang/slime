defmodule Slime.Parser.Nodes do
  defmodule HTMLNode do
    @moduledoc """
    An HTML node.

    * :name — tag name,
    * :attributes — a list of {"name", :v} tuples, where :v is
    either a string or an {:eex, "content"} tuple,
    * :spaces — tag whitespace, represented as a keyword list of boolean
    values for :leading and :trailing,
    * :closed — the presence of a trailing "/", which explicitly closes the tag,
    * :children — a list of nodes.
    """

    defstruct name: "",
              attributes: [],
              spaces: %{},
              closed: false,
              children: []
  end

  defmodule EExNode do
    @moduledoc """
    An embedded code node.

    * :content — embedded code,
    * :output — should the return value be inserted in the page,
    * :spaces — tag whitespace, represented as a keyword list of boolean
    values for :leading and :trailing,
    * :children — a list of nodes.
    * :safe? - mark output as safe for html-escaping engines
    """

    defstruct content: "",
              output: false,
              spaces: %{},
              children: [],
              safe?: false
  end

  defmodule VerbatimTextNode do
    @moduledoc """
    A verbatim text node.

    * :content — a list of strings and %EExNode{} structs that
    is concatenated during rendering. No newlines or spaces
    are inserted between individual items.
    """

    defstruct content: []
  end

  defmodule HTMLCommentNode do
    @moduledoc """
    An HTML comment node.

    Similar to `Slime.Parser.Nodes.VerbatimTextNode`.
    """

    defstruct content: []
  end

  defmodule InlineHTMLNode do
    @moduledoc """
    An inline HTML node.

    Similar to `Slime.Parser.Nodes.VerbatimTextNode`, with the exeption
    of :children field, which represents a list of nodes indented deeper
    than the HTML content.
    """

    defstruct content: [],
              children: []
  end

  defmodule DoctypeNode do
    @moduledoc """
    A doctype node.

    :name is a Slim shorthand (e.g. "xml" or "html").
    """

    defstruct name: ""
  end
end
