Definitions.

Indent = \n\s*
Chars  = .*


Rules.

{Indent} : {token, {indent, indent_value(TokenChars)}}.
{Chars}  : {token, {tag, utf8(TokenChars)}}.


Erlang code.

utf8(X) ->
  unicode:characters_to_binary(X).

indent_value(Chars) ->
  length(Chars) - 1.
