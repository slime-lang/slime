Definitions.

Indent = \n\s*
Chars  = .*


Rules.

{Indent} : {token, {indent, indent_value(TokenChars)}}.
{Chars}  : {token, {tag, TokenChars}}.


Erlang code.

indent_value(Chars) ->
  length(Chars) - 1.
