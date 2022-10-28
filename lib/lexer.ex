defmodule Lexer do
  @spec lex(String.t()) :: list
  def lex(source) do
    whitespace_regex = ~r/^[ \t\n]+/m
    identifier_regex = ~r/^(?:[a-zA-Z!$%&*\/:<=>?^_~][a-zA-Z!$%&*\/:<=>?^_~0-9+\-.@]*)|^[+-]/m
    number_regex = ~r/^[0-9]+/m
    bool_true_regex = ~r/^(?:#t)/m
    bool_false_regex = ~r/^(?:#f)/m
    kw_lambda_regex = ~r/^lambda/m
    kw_if_regex = ~r/^if/m
    kw_define_regex = ~r/^define/m
    kw_set_regex = ~r/^set/m

    cond do
      source == "" ->
        []

      String.starts_with?(source, "(") ->
        {_h, t} = String.split_at(source, 1)

        [
          %Token{token_type: :OpenParen}
          | lex(t)
        ]

      String.starts_with?(source, ")") ->
        {_h, t} = String.split_at(source, 1)

        [
          %Token{token_type: :CloseParen}
          | lex(t)
        ]

      Regex.match?(number_regex, source) ->
        [match | _] = Regex.run(number_regex, source)
        {num, _} = Integer.parse(match)

        [
          %Token{token_type: {:Num, num}}
          | lex(Regex.replace(number_regex, source, "", global: false))
        ]

      Regex.match?(bool_true_regex, source) ->
        [
          %Token{token_type: {:Bool, true}}
          | lex(Regex.replace(bool_true_regex, source, "", global: false))
        ]

      Regex.match?(bool_false_regex, source) ->
        [
          %Token{token_type: {:Bool, false}}
          | lex(Regex.replace(bool_false_regex, source, "", global: false))
        ]

      Regex.match?(kw_lambda_regex, source) ->
        [
          %Token{token_type: :KwLambda}
          | lex(Regex.replace(kw_lambda_regex, source, "", global: false))
        ]

      Regex.match?(kw_if_regex, source) ->
        [
          %Token{token_type: :KwIf}
          | lex(Regex.replace(kw_if_regex, source, "", global: false))
        ]

      Regex.match?(kw_define_regex, source) ->
        [
          %Token{token_type: :KwDefine}
          | lex(Regex.replace(kw_define_regex, source, "", global: false))
        ]

      Regex.match?(kw_set_regex, source) ->
        [
          %Token{token_type: :KwSet}
          | lex(Regex.replace(kw_set_regex, source, "", global: false))
        ]

      Regex.match?(identifier_regex, source) ->
        match = Regex.run(identifier_regex, source)

        [
          %Token{token_type: {:Identifier, match}}
          | lex(Regex.replace(identifier_regex, source, "", global: false))
        ]

      Regex.match?(whitespace_regex, source) ->
        lex(Regex.replace(whitespace_regex, source, "", global: false))

      true ->
        []
    end
  end
end
