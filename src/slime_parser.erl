-module(slime_parser).
-export([parse/1,file/1]).
-define(p_anything,true).
-define(p_assert,true).
-define(p_charclass,true).
-define(p_choose,true).
-define(p_label,true).
-define(p_not,true).
-define(p_one_or_more,true).
-define(p_optional,true).
-define(p_scan,true).
-define(p_seq,true).
-define(p_string,true).
-define(p_zero_or_more,true).



-spec file(file:name()) -> any().
file(Filename) -> case file:read_file(Filename) of {ok,Bin} -> parse(Bin); Err -> Err end.

-spec parse(binary() | list()) -> any().
parse(List) when is_list(List) -> parse(unicode:characters_to_binary(List));
parse(Input) when is_binary(Input) ->
  _ = setup_memo(),
  Result = case 'document'(Input,{{line,1},{column,1}}) of
             {AST, <<>>, _Index} -> AST;
             Any -> Any
           end,
  release_memo(), Result.

-spec 'document'(input(), index()) -> parse_result().
'document'(Input, Index) ->
  p(Input, Index, 'document', fun(I,D) -> (p_seq([p_optional(fun 'doctype'/2), fun 'tags_list'/2, p_zero_or_more(fun 'crlf'/2), fun 'eof'/2]))(I,D) end, fun(Node, Idx) ->transform('document', Node, Idx) end).

-spec 'doctype'(input(), index()) -> parse_result().
'doctype'(Input, Index) ->
  p(Input, Index, 'doctype', fun(I,D) -> (p_seq([p_optional(fun 'space'/2), p_string(<<"doctype">>), fun 'space'/2, p_one_or_more(p_seq([p_not(fun 'eol'/2), p_anything()])), fun 'eol'/2]))(I,D) end, fun(Node, Idx) ->transform('doctype', Node, Idx) end).

-spec 'tags_list'(input(), index()) -> parse_result().
'tags_list'(Input, Index) ->
  p(Input, Index, 'tags_list', fun(I,D) -> (p_seq([fun 'tag'/2, p_zero_or_more(p_seq([fun 'crlf'/2, p_optional(fun 'indent'/2), p_label('empty_lines', p_zero_or_more(p_seq([p_optional(fun 'space'/2), fun 'crlf'/2, p_optional(fun 'indent'/2)]))), p_label('tag', fun 'tag'/2), p_zero_or_more(fun 'dedent'/2)]))]))(I,D) end, fun(Node, Idx) ->transform('tags_list', Node, Idx) end).

-spec 'tag'(input(), index()) -> parse_result().
'tag'(Input, Index) ->
  p(Input, Index, 'tag', fun(I,D) -> (p_choose([fun 'verbatim_text'/2, p_seq([p_optional(fun 'space'/2), fun 'tag_item'/2]), p_label('blank', p_seq([p_optional(fun 'space'/2), p_assert(fun 'eol'/2)]))]))(I,D) end, fun(Node, Idx) ->transform('tag', Node, Idx) end).

-spec 'tag_item'(input(), index()) -> parse_result().
'tag_item'(Input, Index) ->
  p(Input, Index, 'tag_item', fun(I,D) -> (p_choose([fun 'embedded_engine'/2, fun 'comment'/2, fun 'inline_html'/2, fun 'code'/2, fun 'html_tag'/2]))(I,D) end, fun(Node, Idx) ->transform('tag_item', Node, Idx) end).

-spec 'inline_html'(input(), index()) -> parse_result().
'inline_html'(Input, Index) ->
  p(Input, Index, 'inline_html', fun(I,D) -> (p_seq([p_assert(p_string(<<"<">>)), fun 'text_content'/2]))(I,D) end, fun(Node, Idx) ->transform('inline_html', Node, Idx) end).

-spec 'code'(input(), index()) -> parse_result().
'code'(Input, Index) ->
  p(Input, Index, 'code', fun(I,D) -> (p_seq([p_label('inline', p_choose([p_seq([p_string(<<"=">>), p_optional(p_string(<<"=">>))]), p_string(<<"-">>)])), p_optional(fun 'space'/2), p_label('code', fun 'code_lines'/2)]))(I,D) end, fun(Node, Idx) ->transform('code', Node, Idx) end).

-spec 'code_lines'(input(), index()) -> parse_result().
'code_lines'(Input, Index) ->
  p(Input, Index, 'code_lines', fun(I,D) -> (p_choose([fun 'code_line'/2, p_seq([fun 'code_line_with_brake'/2, fun 'crlf'/2, p_choose([p_seq([fun 'indent'/2, fun 'code_lines'/2, fun 'dedent'/2]), fun 'code_lines'/2])])]))(I,D) end, fun(Node, Idx) ->transform('code_lines', Node, Idx) end).

-spec 'code_line'(input(), index()) -> parse_result().
'code_line'(Input, Index) ->
  p(Input, Index, 'code_line', fun(I,D) -> (p_seq([p_zero_or_more(p_seq([p_not(p_seq([p_anything(), fun 'eol'/2])), p_anything()])), p_not(fun 'code_line_break'/2), p_anything(), p_assert(fun 'eol'/2)]))(I,D) end, fun(Node, Idx) ->transform('code_line', Node, Idx) end).

-spec 'code_line_with_brake'(input(), index()) -> parse_result().
'code_line_with_brake'(Input, Index) ->
  p(Input, Index, 'code_line_with_brake', fun(I,D) -> (p_seq([p_zero_or_more(p_seq([p_not(p_seq([p_anything(), fun 'eol'/2])), p_anything()])), fun 'code_line_break'/2, p_assert(fun 'eol'/2)]))(I,D) end, fun(Node, Idx) ->transform('code_line_with_brake', Node, Idx) end).

-spec 'code_line_break'(input(), index()) -> parse_result().
'code_line_break'(Input, Index) ->
  p(Input, Index, 'code_line_break', fun(I,D) -> (p_choose([p_string(<<",">>), p_string(<<"\\">>)]))(I,D) end, fun(Node, Idx) ->transform('code_line_break', Node, Idx) end).

-spec 'html_tag'(input(), index()) -> parse_result().
'html_tag'(Input, Index) ->
  p(Input, Index, 'html_tag', fun(I,D) -> (p_choose([fun 'inline_tag'/2, fun 'simple_tag'/2]))(I,D) end, fun(Node, Idx) ->transform('html_tag', Node, Idx) end).

-spec 'inline_tag'(input(), index()) -> parse_result().
'inline_tag'(Input, Index) ->
  p(Input, Index, 'inline_tag', fun(I,D) -> (p_seq([p_label('tag', fun 'tag_shortcut'/2), p_string(<<":">>), fun 'space'/2, p_label('children', fun 'simple_tag'/2)]))(I,D) end, fun(Node, Idx) ->transform('inline_tag', Node, Idx) end).

-spec 'simple_tag'(input(), index()) -> parse_result().
'simple_tag'(Input, Index) ->
  p(Input, Index, 'simple_tag', fun(I,D) -> (p_seq([p_label('tag', fun 'tag_shortcut'/2), p_label('spaces', p_optional(fun 'tag_spaces'/2)), p_label('attrs', p_optional(p_seq([p_optional(fun 'space'/2), fun 'attributes'/2]))), p_label('content', p_optional(p_choose([p_seq([p_optional(fun 'space'/2), p_string(<<"\/">>)]), p_seq([p_optional(fun 'space'/2), fun 'dynamic_content'/2]), p_seq([fun 'space'/2, fun 'text_content'/2])])))]))(I,D) end, fun(Node, Idx) ->transform('simple_tag', Node, Idx) end).

-spec 'text_content'(input(), index()) -> parse_result().
'text_content'(Input, Index) ->
  p(Input, Index, 'text_content', fun(I,D) -> (p_choose([p_label('dynamic', fun 'text_with_interpolation'/2), p_label('simple', fun 'text'/2)]))(I,D) end, fun(Node, Idx) ->transform('text_content', Node, Idx) end).

-spec 'dynamic_content'(input(), index()) -> parse_result().
'dynamic_content'(Input, Index) ->
  p(Input, Index, 'dynamic_content', fun(I,D) -> (p_seq([p_string(<<"=">>), p_optional(p_string(<<"=">>)), p_optional(fun 'space'/2), p_one_or_more(p_seq([p_not(fun 'eol'/2), p_anything()]))]))(I,D) end, fun(Node, Idx) ->transform('dynamic_content', Node, Idx) end).

-spec 'tag_spaces'(input(), index()) -> parse_result().
'tag_spaces'(Input, Index) ->
  p(Input, Index, 'tag_spaces', fun(I,D) -> (p_seq([p_label('leading', p_optional(p_string(<<"<">>))), p_label('trailing', p_optional(p_string(<<">">>)))]))(I,D) end, fun(Node, Idx) ->transform('tag_spaces', Node, Idx) end).

-spec 'tag_shortcut'(input(), index()) -> parse_result().
'tag_shortcut'(Input, Index) ->
  p(Input, Index, 'tag_shortcut', fun(I,D) -> (p_choose([p_seq([p_label('tag', fun 'tag_name'/2), p_label('attrs', fun 'shortcuts'/2)]), p_label('tag', fun 'tag_name'/2), p_label('attrs', fun 'shortcuts'/2)]))(I,D) end, fun(Node, Idx) ->transform('tag_shortcut', Node, Idx) end).

-spec 'shortcuts'(input(), index()) -> parse_result().
'shortcuts'(Input, Index) ->
  p(Input, Index, 'shortcuts', fun(I,D) -> (p_seq([p_label('head', fun 'shortcut'/2), p_label('tail', p_zero_or_more(fun 'shortcut'/2))]))(I,D) end, fun(Node, Idx) ->transform('shortcuts', Node, Idx) end).

-spec 'shortcut'(input(), index()) -> parse_result().
'shortcut'(Input, Index) ->
  p(Input, Index, 'shortcut', fun(I,D) -> (p_seq([p_label('type', p_choose([p_string(<<".">>), p_string(<<"#">>), p_string(<<"@">>), p_string(<<"$">>), p_string(<<"%">>), p_string(<<"^">>), p_string(<<"&">>), p_string(<<"+">>), p_string(<<"!">>)])), p_label('value', fun 'tag_name'/2)]))(I,D) end, fun(Node, Idx) ->transform('shortcut', Node, Idx) end).

-spec 'attributes'(input(), index()) -> parse_result().
'attributes'(Input, Index) ->
  p(Input, Index, 'attributes', fun(I,D) -> (p_choose([fun 'wrapped_attributes'/2, fun 'plain_attributes'/2]))(I,D) end, fun(Node, Idx) ->transform('attributes', Node, Idx) end).

-spec 'wrapped_attributes'(input(), index()) -> parse_result().
'wrapped_attributes'(Input, Index) ->
  p(Input, Index, 'wrapped_attributes', fun(I,D) -> (p_choose([p_seq([p_string(<<"[">>), fun 'wrapped_attributes_list'/2, p_string(<<"]">>)]), p_seq([p_string(<<"(">>), fun 'wrapped_attributes_list'/2, p_string(<<")">>)]), p_seq([p_string(<<"{">>), fun 'wrapped_attributes_list'/2, p_string(<<"}">>)])]))(I,D) end, fun(Node, Idx) ->transform('wrapped_attributes', Node, Idx) end).

-spec 'wrapped_attributes_list'(input(), index()) -> parse_result().
'wrapped_attributes_list'(Input, Index) ->
  p(Input, Index, 'wrapped_attributes_list', fun(I,D) -> (p_seq([p_label('head', fun 'wrapped_attribute'/2), p_label('tail', p_zero_or_more(p_seq([fun 'space'/2, fun 'wrapped_attribute'/2])))]))(I,D) end, fun(Node, Idx) ->transform('wrapped_attributes_list', Node, Idx) end).

-spec 'wrapped_attribute'(input(), index()) -> parse_result().
'wrapped_attribute'(Input, Index) ->
  p(Input, Index, 'wrapped_attribute', fun(I,D) -> (p_choose([p_label('attribute', fun 'attribute'/2), p_label('attribute_name', fun 'tag_name'/2)]))(I,D) end, fun(Node, Idx) ->transform('wrapped_attribute', Node, Idx) end).

-spec 'plain_attributes'(input(), index()) -> parse_result().
'plain_attributes'(Input, Index) ->
  p(Input, Index, 'plain_attributes', fun(I,D) -> (p_seq([p_label('head', fun 'attribute'/2), p_label('tail', p_zero_or_more(p_seq([fun 'space'/2, fun 'attribute'/2])))]))(I,D) end, fun(Node, Idx) ->transform('plain_attributes', Node, Idx) end).

-spec 'attribute'(input(), index()) -> parse_result().
'attribute'(Input, Index) ->
  p(Input, Index, 'attribute', fun(I,D) -> (p_seq([fun 'attribute_name'/2, p_string(<<"=">>), fun 'attribute_value'/2]))(I,D) end, fun(Node, Idx) ->transform('attribute', Node, Idx) end).

-spec 'attribute_value'(input(), index()) -> parse_result().
'attribute_value'(Input, Index) ->
  p(Input, Index, 'attribute_value', fun(I,D) -> (p_choose([p_label('simple', fun 'string'/2), p_label('dynamic', p_choose([fun 'string_with_interpolation'/2, fun 'attribute_code'/2]))]))(I,D) end, fun(Node, Idx) ->transform('attribute_value', Node, Idx) end).

-spec 'string'(input(), index()) -> parse_result().
'string'(Input, Index) ->
  p(Input, Index, 'string', fun(I,D) -> (p_seq([p_string(<<"\"">>), p_zero_or_more(p_choose([p_seq([p_string(<<"\\">>), p_anything()]), p_seq([p_not(p_choose([p_string(<<"\"">>), p_string(<<"#">>)])), p_anything()])])), p_string(<<"\"">>)]))(I,D) end, fun(Node, Idx) ->transform('string', Node, Idx) end).

-spec 'string_with_interpolation'(input(), index()) -> parse_result().
'string_with_interpolation'(Input, Index) ->
  p(Input, Index, 'string_with_interpolation', fun(I,D) -> (p_seq([p_string(<<"\"">>), p_zero_or_more(p_choose([fun 'interpolation'/2, p_seq([p_string(<<"\\">>), p_anything()]), p_seq([p_not(p_string(<<"\"">>)), p_anything()])])), p_string(<<"\"">>)]))(I,D) end, fun(Node, Idx) ->transform('string_with_interpolation', Node, Idx) end).

-spec 'attribute_code'(input(), index()) -> parse_result().
'attribute_code'(Input, Index) ->
  p(Input, Index, 'attribute_code', fun(I,D) -> (p_one_or_more(p_choose([fun 'parentheses'/2, fun 'brackets'/2, fun 'braces'/2, p_seq([p_not(p_choose([fun 'space'/2, fun 'eol'/2, p_string(<<")">>), p_string(<<"]">>), p_string(<<"}">>)])), p_anything()])])))(I,D) end, fun(Node, Idx) ->transform('attribute_code', Node, Idx) end).

-spec 'text_with_interpolation'(input(), index()) -> parse_result().
'text_with_interpolation'(Input, Index) ->
  p(Input, Index, 'text_with_interpolation', fun(I,D) -> (p_seq([p_one_or_more(p_seq([fun 'text'/2, fun 'interpolation'/2])), p_zero_or_more(p_seq([p_not(fun 'eol'/2), p_anything()]))]))(I,D) end, fun(Node, Idx) ->transform('text_with_interpolation', Node, Idx) end).

-spec 'text'(input(), index()) -> parse_result().
'text'(Input, Index) ->
  p(Input, Index, 'text', fun(I,D) -> (p_zero_or_more(p_choose([p_seq([p_string(<<"\\">>), p_anything()]), p_seq([p_not(p_choose([p_string(<<"#{">>), fun 'eol'/2])), p_anything()])])))(I,D) end, fun(Node, Idx) ->transform('text', Node, Idx) end).

-spec 'parentheses'(input(), index()) -> parse_result().
'parentheses'(Input, Index) ->
  p(Input, Index, 'parentheses', fun(I,D) -> (p_seq([p_string(<<"(">>), p_zero_or_more(p_choose([fun 'parentheses'/2, p_seq([p_not(p_string(<<")">>)), p_anything()])])), p_string(<<")">>)]))(I,D) end, fun(Node, Idx) ->transform('parentheses', Node, Idx) end).

-spec 'brackets'(input(), index()) -> parse_result().
'brackets'(Input, Index) ->
  p(Input, Index, 'brackets', fun(I,D) -> (p_seq([p_string(<<"[">>), p_zero_or_more(p_choose([fun 'brackets'/2, p_seq([p_not(p_string(<<"]">>)), p_anything()])])), p_string(<<"]">>)]))(I,D) end, fun(Node, Idx) ->transform('brackets', Node, Idx) end).

-spec 'braces'(input(), index()) -> parse_result().
'braces'(Input, Index) ->
  p(Input, Index, 'braces', fun(I,D) -> (p_seq([p_string(<<"{">>), p_zero_or_more(p_choose([fun 'braces'/2, p_seq([p_not(p_string(<<"}">>)), p_anything()])])), p_string(<<"}">>)]))(I,D) end, fun(Node, Idx) ->transform('braces', Node, Idx) end).

-spec 'interpolation'(input(), index()) -> parse_result().
'interpolation'(Input, Index) ->
  p(Input, Index, 'interpolation', fun(I,D) -> (p_seq([p_string(<<"#{">>), p_zero_or_more(p_choose([fun 'string'/2, fun 'string_with_interpolation'/2, p_seq([p_not(p_string(<<"}">>)), p_anything()])])), p_string(<<"}">>)]))(I,D) end, fun(Node, Idx) ->transform('interpolation', Node, Idx) end).

-spec 'comment'(input(), index()) -> parse_result().
'comment'(Input, Index) ->
  p(Input, Index, 'comment', fun(I,D) -> (p_choose([fun 'html_comment'/2, fun 'ie_comment'/2, fun 'code_comment'/2]))(I,D) end, fun(Node, Idx) ->transform('comment', Node, Idx) end).

-spec 'html_comment'(input(), index()) -> parse_result().
'html_comment'(Input, Index) ->
  p(Input, Index, 'html_comment', fun(I,D) -> (p_seq([p_string(<<"\/!">>), p_optional(fun 'space'/2), p_zero_or_more(p_seq([p_not(fun 'eol'/2), p_anything()]))]))(I,D) end, fun(Node, Idx) ->transform('html_comment', Node, Idx) end).

-spec 'ie_comment'(input(), index()) -> parse_result().
'ie_comment'(Input, Index) ->
  p(Input, Index, 'ie_comment', fun(I,D) -> (p_seq([p_string(<<"\/[">>), p_label('condition', p_one_or_more(p_seq([p_not(p_string(<<"]">>)), p_anything()]))), p_string(<<"]">>), p_optional(fun 'space'/2), p_label('content', p_zero_or_more(p_seq([p_not(fun 'eol'/2), p_anything()])))]))(I,D) end, fun(Node, Idx) ->transform('ie_comment', Node, Idx) end).

-spec 'code_comment'(input(), index()) -> parse_result().
'code_comment'(Input, Index) ->
  p(Input, Index, 'code_comment', fun(I,D) -> (p_seq([p_string(<<"\/">>), p_zero_or_more(p_seq([p_not(fun 'eol'/2), p_anything()]))]))(I,D) end, fun(Node, Idx) ->transform('code_comment', Node, Idx) end).

-spec 'verbatim_text'(input(), index()) -> parse_result().
'verbatim_text'(Input, Index) ->
  p(Input, Index, 'verbatim_text', fun(I,D) -> (p_seq([p_label('indent', p_optional(fun 'space'/2)), p_label('type', p_charclass(<<"[|\']">>)), p_label('space', p_optional(fun 'space'/2)), p_label('content', fun 'verbatim_text_lines'/2)]))(I,D) end, fun(Node, Idx) ->transform('verbatim_text', Node, Idx) end).

-spec 'verbatim_text_lines'(input(), index()) -> parse_result().
'verbatim_text_lines'(Input, Index) ->
  p(Input, Index, 'verbatim_text_lines', fun(I,D) -> (p_seq([fun 'verbatim_text_line'/2, p_optional(p_seq([fun 'crlf'/2, fun 'indent'/2, p_label('space', fun 'space'/2), p_label('lines', fun 'verbatim_text_nested_lines'/2), fun 'dedent'/2]))]))(I,D) end, fun(Node, Idx) ->transform('verbatim_text_lines', Node, Idx) end).

-spec 'verbatim_text_nested_lines'(input(), index()) -> parse_result().
'verbatim_text_nested_lines'(Input, Index) ->
  p(Input, Index, 'verbatim_text_nested_lines', fun(I,D) -> (p_seq([fun 'verbatim_text_line'/2, p_zero_or_more(p_seq([fun 'crlf'/2, p_choose([p_seq([fun 'indent'/2, p_label('space', fun 'space'/2), p_label('lines', fun 'verbatim_text_nested_lines'/2), fun 'dedent'/2]), p_seq([p_label('space', fun 'space'/2), p_label('lines', fun 'verbatim_text_nested_lines'/2)])])]))]))(I,D) end, fun(Node, Idx) ->transform('verbatim_text_nested_lines', Node, Idx) end).

-spec 'verbatim_text_line'(input(), index()) -> parse_result().
'verbatim_text_line'(Input, Index) ->
  p(Input, Index, 'verbatim_text_line', fun(I,D) -> (p_choose([p_label('dynamic', fun 'text_with_interpolation'/2), p_label('simple', fun 'text'/2), p_string(<<"">>)]))(I,D) end, fun(Node, Idx) ->transform('verbatim_text_line', Node, Idx) end).

-spec 'embedded_engine'(input(), index()) -> parse_result().
'embedded_engine'(Input, Index) ->
  p(Input, Index, 'embedded_engine', fun(I,D) -> (p_seq([fun 'tag_name'/2, p_string(<<":">>), p_choose([p_one_or_more(p_seq([fun 'crlf'/2, fun 'indent'/2, p_label('lines', fun 'embedded_engine_lines'/2), fun 'dedent'/2])), p_label('empty', p_seq([p_string(<<"">>), p_assert(fun 'eol'/2)]))])]))(I,D) end, fun(Node, Idx) ->transform('embedded_engine', Node, Idx) end).

-spec 'embedded_engine_lines'(input(), index()) -> parse_result().
'embedded_engine_lines'(Input, Index) ->
  p(Input, Index, 'embedded_engine_lines', fun(I,D) -> (p_seq([fun 'embedded_engine_line'/2, p_zero_or_more(p_seq([fun 'crlf'/2, p_choose([p_seq([fun 'indent'/2, p_label('lines', fun 'embedded_engine_lines'/2), fun 'dedent'/2]), p_label('lines', fun 'embedded_engine_lines'/2)])]))]))(I,D) end, fun(Node, Idx) ->transform('embedded_engine_lines', Node, Idx) end).

-spec 'embedded_engine_line'(input(), index()) -> parse_result().
'embedded_engine_line'(Input, Index) ->
  p(Input, Index, 'embedded_engine_line', fun(I,D) -> (p_choose([fun 'text_with_interpolation'/2, fun 'text'/2, p_string(<<"">>)]))(I,D) end, fun(Node, Idx) ->transform('embedded_engine_line', Node, Idx) end).

-spec 'tag_name'(input(), index()) -> parse_result().
'tag_name'(Input, Index) ->
  p(Input, Index, 'tag_name', fun(I,D) -> (p_one_or_more(p_charclass(<<"[a-zA-Z0-9_-]">>)))(I,D) end, fun(Node, Idx) ->transform('tag_name', Node, Idx) end).

-spec 'attribute_name'(input(), index()) -> parse_result().
'attribute_name'(Input, Index) ->
  p(Input, Index, 'attribute_name', fun(I,D) -> (p_one_or_more(p_charclass(<<"[a-zA-Z0-9_@:-]">>)))(I,D) end, fun(Node, Idx) ->transform('attribute_name', Node, Idx) end).

-spec 'space'(input(), index()) -> parse_result().
'space'(Input, Index) ->
  p(Input, Index, 'space', fun(I,D) -> (p_one_or_more(p_charclass(<<"[\s\t]">>)))(I,D) end, fun(Node, Idx) ->transform('space', Node, Idx) end).

-spec 'indent'(input(), index()) -> parse_result().
'indent'(Input, Index) ->
  p(Input, Index, 'indent', fun(I,D) -> (p_string(<<"\x{0E}">>))(I,D) end, fun(Node, Idx) ->transform('indent', Node, Idx) end).

-spec 'dedent'(input(), index()) -> parse_result().
'dedent'(Input, Index) ->
  p(Input, Index, 'dedent', fun(I,D) -> (p_string(<<"\x{0F}">>))(I,D) end, fun(Node, Idx) ->transform('dedent', Node, Idx) end).

-spec 'crlf'(input(), index()) -> parse_result().
'crlf'(Input, Index) ->
  p(Input, Index, 'crlf', fun(I,D) -> (p_seq([p_optional(p_string(<<"\r">>)), p_string(<<"\n">>)]))(I,D) end, fun(Node, Idx) ->transform('crlf', Node, Idx) end).

-spec 'eof'(input(), index()) -> parse_result().
'eof'(Input, Index) ->
  p(Input, Index, 'eof', fun(I,D) -> (p_not(p_anything()))(I,D) end, fun(Node, Idx) ->transform('eof', Node, Idx) end).

-spec 'eol'(input(), index()) -> parse_result().
'eol'(Input, Index) ->
  p(Input, Index, 'eol', fun(I,D) -> (p_choose([fun 'dedent'/2, fun 'crlf'/2, fun 'eof'/2]))(I,D) end, fun(Node, Idx) ->transform('eol', Node, Idx) end).


transform(Symbol,Node,Index) -> slime_parser_transform:transform(Symbol, Node, Index).
-file("peg_includes.hrl", 1).
-type index() :: {{line, pos_integer()}, {column, pos_integer()}}.
-type input() :: binary().
-type parse_failure() :: {fail, term()}.
-type parse_success() :: {term(), input(), index()}.
-type parse_result() :: parse_failure() | parse_success().
-type parse_fun() :: fun((input(), index()) -> parse_result()).
-type xform_fun() :: fun((input(), index()) -> term()).

-spec p(input(), index(), atom(), parse_fun(), xform_fun()) -> parse_result().
p(Inp, StartIndex, Name, ParseFun, TransformFun) ->
  case get_memo(StartIndex, Name) of      % See if the current reduction is memoized
    {ok, Memo} -> %Memo;                     % If it is, return the stored result
      Memo;
    _ ->                                        % If not, attempt to parse
      Result = case ParseFun(Inp, StartIndex) of
        {fail,_} = Failure ->                       % If it fails, memoize the failure
          Failure;
        {Match, InpRem, NewIndex} ->               % If it passes, transform and memoize the result.
          Transformed = TransformFun(Match, StartIndex),
          {Transformed, InpRem, NewIndex}
      end,
      memoize(StartIndex, Name, Result),
      Result
  end.

-spec setup_memo() -> ets:tid().
setup_memo() ->
  put({parse_memo_table, ?MODULE}, ets:new(?MODULE, [set])).

-spec release_memo() -> true.
release_memo() ->
  ets:delete(memo_table_name()).

-spec memoize(index(), atom(), parse_result()) -> true.
memoize(Index, Name, Result) ->
  Memo = case ets:lookup(memo_table_name(), Index) of
              [] -> [];
              [{Index, Plist}] -> Plist
         end,
  ets:insert(memo_table_name(), {Index, [{Name, Result}|Memo]}).

-spec get_memo(index(), atom()) -> {ok, term()} | {error, not_found}.
get_memo(Index, Name) ->
  case ets:lookup(memo_table_name(), Index) of
    [] -> {error, not_found};
    [{Index, Plist}] ->
      case proplists:lookup(Name, Plist) of
        {Name, Result}  -> {ok, Result};
        _  -> {error, not_found}
      end
    end.

-spec memo_table_name() -> ets:tid().
memo_table_name() ->
    get({parse_memo_table, ?MODULE}).

-ifdef(p_eof).
-spec p_eof() -> parse_fun().
p_eof() ->
  fun(<<>>, Index) -> {eof, [], Index};
     (_, Index) -> {fail, {expected, eof, Index}} end.
-endif.

-ifdef(p_optional).
-spec p_optional(parse_fun()) -> parse_fun().
p_optional(P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} -> {[], Input, Index};
        {_, _, _} = Success -> Success
      end
  end.
-endif.

-ifdef(p_not).
-spec p_not(parse_fun()) -> parse_fun().
p_not(P) ->
  fun(Input, Index)->
      case P(Input,Index) of
        {fail,_} ->
          {[], Input, Index};
        {Result, _, _} -> {fail, {expected, {no_match, Result},Index}}
      end
  end.
-endif.

-ifdef(p_assert).
-spec p_assert(parse_fun()) -> parse_fun().
p_assert(P) ->
  fun(Input,Index) ->
      case P(Input,Index) of
        {fail,_} = Failure-> Failure;
        _ -> {[], Input, Index}
      end
  end.
-endif.

-ifdef(p_seq).
-spec p_seq([parse_fun()]) -> parse_fun().
p_seq(P) ->
  fun(Input, Index) ->
      p_all(P, Input, Index, [])
  end.

-spec p_all([parse_fun()], input(), index(), [term()]) -> parse_result().
p_all([], Inp, Index, Accum ) -> {lists:reverse( Accum ), Inp, Index};
p_all([P|Parsers], Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail, _} = Failure -> Failure;
    {Result, InpRem, NewIndex} -> p_all(Parsers, InpRem, NewIndex, [Result|Accum])
  end.
-endif.

-ifdef(p_choose).
-spec p_choose([parse_fun()]) -> parse_fun().
p_choose(Parsers) ->
  fun(Input, Index) ->
      p_attempt(Parsers, Input, Index, none)
  end.

-spec p_attempt([parse_fun()], input(), index(), none | parse_failure()) -> parse_result().
p_attempt([], _Input, _Index, Failure) -> Failure;
p_attempt([P|Parsers], Input, Index, FirstFailure)->
  case P(Input, Index) of
    {fail, _} = Failure ->
      case FirstFailure of
        none -> p_attempt(Parsers, Input, Index, Failure);
        _ -> p_attempt(Parsers, Input, Index, FirstFailure)
      end;
    Result -> Result
  end.
-endif.

-ifdef(p_zero_or_more).
-spec p_zero_or_more(parse_fun()) -> parse_fun().
p_zero_or_more(P) ->
  fun(Input, Index) ->
      p_scan(P, Input, Index, [])
  end.
-endif.

-ifdef(p_one_or_more).
-spec p_one_or_more(parse_fun()) -> parse_fun().
p_one_or_more(P) ->
  fun(Input, Index)->
      Result = p_scan(P, Input, Index, []),
      case Result of
        {[_|_], _, _} ->
          Result;
        _ ->
          {fail, {expected, Failure, _}} = P(Input,Index),
          {fail, {expected, {at_least_one, Failure}, Index}}
      end
  end.
-endif.

-ifdef(p_label).
-spec p_label(atom(), parse_fun()) -> parse_fun().
p_label(Tag, P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} = Failure ->
           Failure;
        {Result, InpRem, NewIndex} ->
          {{Tag, Result}, InpRem, NewIndex}
      end
  end.
-endif.

-ifdef(p_scan).
-spec p_scan(parse_fun(), input(), index(), [term()]) -> {[term()], input(), index()}.
p_scan(_, <<>>, Index, Accum) -> {lists:reverse(Accum), <<>>, Index};
p_scan(P, Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail,_} -> {lists:reverse(Accum), Inp, Index};
    {Result, InpRem, NewIndex} -> p_scan(P, InpRem, NewIndex, [Result | Accum])
  end.
-endif.

-ifdef(p_string).
-spec p_string(binary()) -> parse_fun().
p_string(S) ->
    Length = erlang:byte_size(S),
    fun(Input, Index) ->
      try
          <<S:Length/binary, Rest/binary>> = Input,
          {S, Rest, p_advance_index(S, Index)}
      catch
          error:{badmatch,_} -> {fail, {expected, {string, S}, Index}}
      end
    end.
-endif.

-ifdef(p_anything).
-spec p_anything() -> parse_fun().
p_anything() ->
  fun(<<>>, Index) -> {fail, {expected, any_character, Index}};
     (Input, Index) when is_binary(Input) ->
          <<C/utf8, Rest/binary>> = Input,
          {<<C/utf8>>, Rest, p_advance_index(<<C/utf8>>, Index)}
  end.
-endif.

-ifdef(p_charclass).
-spec p_charclass(string() | binary()) -> parse_fun().
p_charclass(Class) ->
    {ok, RE} = re:compile(Class, [unicode, dotall]),
    fun(Inp, Index) ->
            case re:run(Inp, RE, [anchored]) of
                {match, [{0, Length}|_]} ->
                    {Head, Tail} = erlang:split_binary(Inp, Length),
                    {Head, Tail, p_advance_index(Head, Index)};
                _ -> {fail, {expected, {character_class, binary_to_list(Class)}, Index}}
            end
    end.
-endif.

-ifdef(p_regexp).
-spec p_regexp(binary()) -> parse_fun().
p_regexp(Regexp) ->
    {ok, RE} = re:compile(Regexp, [unicode, dotall, anchored]),
    fun(Inp, Index) ->
        case re:run(Inp, RE) of
            {match, [{0, Length}|_]} ->
                {Head, Tail} = erlang:split_binary(Inp, Length),
                {Head, Tail, p_advance_index(Head, Index)};
            _ -> {fail, {expected, {regexp, binary_to_list(Regexp)}, Index}}
        end
    end.
-endif.

-ifdef(line).
-spec line(index() | term()) -> pos_integer() | undefined.
line({{line,L},_}) -> L;
line(_) -> undefined.
-endif.

-ifdef(column).
-spec column(index() | term()) -> pos_integer() | undefined.
column({_,{column,C}}) -> C;
column(_) -> undefined.
-endif.

-spec p_advance_index(input() | unicode:charlist() | pos_integer(), index()) -> index().
p_advance_index(MatchedInput, Index) when is_list(MatchedInput) orelse is_binary(MatchedInput)-> % strings
  lists:foldl(fun p_advance_index/2, Index, unicode:characters_to_list(MatchedInput));
p_advance_index(MatchedInput, Index) when is_integer(MatchedInput) -> % single characters
  {{line, Line}, {column, Col}} = Index,
  case MatchedInput of
    $\n -> {{line, Line+1}, {column, 1}};
    _ -> {{line, Line}, {column, Col+1}}
  end.
