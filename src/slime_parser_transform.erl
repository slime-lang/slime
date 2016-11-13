-module(slime_parser_transform).
-export([transform/3]).

%% Add clauses to this function to transform syntax nodes
%% from the parser into semantic output.
transform(Symbol, Node, Index) when is_atom(Symbol) ->
  %% TODO: allow elixir modules as transform_module in neotoma:file/2
  'Elixir.Slime.Parser.Transform':transform(Symbol, Node, Index).
