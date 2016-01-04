Definitions.

Indent = \n\s*
Class  = \.[a-z][a-z0-9-]*
ID     = #[a-z][a-z0-9-]*
Chars  = .*


Rules.

{Indent} : {token, {indent, indent_value(TokenChars)}}.
{Class}  : {token, {class,  utf8(tl(TokenChars))}}.
{ID}     : {token, {id,     utf8(tl(TokenChars))}}.
{Chars}  : {token, {tag,    utf8(TokenChars)}}.


Erlang code.

utf8(X) ->
  unicode:characters_to_binary(X).

indent_value(Chars) ->
  length(Chars) - 1.
