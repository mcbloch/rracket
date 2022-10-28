defmodule Parser do
  @moduledoc false

  defmodule NodeCall do
    defstruct([:operator, :operands])
  end

  defmodule NodeExpr do
    defstruct([:v])

    @type t ::
            :constant
            | :identifier
            | :call
  end

  defmodule NodeIdentifier do
    defstruct([:v])
  end

  defmodule NodeLambda do
    defstruct([:formals, :body])
  end

  defmodule NodeDefine do
    defstruct([:variable, :expression])
  end

  defmodule NodeIf do
    defstruct([:test, :consequent, :alternate])
  end

  defmodule NodeConst do
    defstruct([:v])

    @type t ::
            :bool
            | :number
            | :string
  end

  def parse([]) do
    []
  end

  def parse(tokens) do
    {somethingfuu, others} = parse_expr(tokens)

    [somethingfuu | parse(others)]
  end

  def parse_expr([%Token{token_type: {:Num, _}} = t | tokens]) do
    {%NodeConst{v: t}, tokens}
  end

  def parse_expr([%Token{token_type: {:Bool, _}} = t | tokens]) do
    {%NodeConst{v: t}, tokens}
  end

  def parse_expr([%Token{token_type: {:Identifier, _}} = t | tokens]) do
    {%NodeIdentifier{v: t}, tokens}
  end

  def parse_expr([%Token{token_type: :OpenParen} | tokens]) do
    [token | tail] = tokens

    case token do
      %Token{token_type: :KwLambda} ->
        {formals, resting_tokens} = parse_formals(tail)
        {body, [close | close_tail]} = build_expr_list(resting_tokens, [])

        if close.token_type != :CloseParen do
          raise "Lambdas should end with a closing bracket"
        end

        {%NodeLambda{formals: formals, body: body}, close_tail}

      %Token{token_type: :KwDefine} ->
        [identifier | identifier_tail] = tail

        if identifier.token_type |> elem(0) != :Identifier do
          raise "A define should be followed by an identifier"
        end

        {expression, [close | close_tail] = others} = parse_expr(identifier_tail)

        if close.token_type != :CloseParen do
          raise "Defines should end with a closing bracket"
        end

        {%NodeDefine{variable: identifier, expression: expression}, close_tail}

      %Token{token_type: :KwIf} ->
        {test, test_tail} = parse_expr(tail)
        {consequent, [close | close_tail] = consequent_tail} = parse_expr(test_tail)

        if close.token_type == :CloseParen do
          {%NodeIf{test: test, consequent: consequent}, close_tail}
        else
          {alternate, [alternate_close | alternate_close_tail]} = parse_expr(consequent_tail)

          if alternate_close.token_type != :CloseParen do
            raise "Ifs should end with a closing bracket"
          end

          {%NodeIf{test: test, consequent: consequent, alternate: alternate},
           alternate_close_tail}
        end

      %Token{token_type: {:Identifier, _}} ->
        {operands, [close | operands_close]} = build_expr_list(tail, [])

        if close.token_type != :CloseParen do
          raise "Calls should end with a closing bracket"
        end

        {%NodeCall{operator: token, operands: operands}, operands_close}
    end
  end

  def parse_formals([h | tail]) do
    case h do
      %Token{token_type: {:Identifier, _}} ->
        {[h], tail}

      %Token{token_type: :OpenParen} ->
        {formals, [close | formals_tail] = others} =
          Enum.split_while(tail, fn token ->
            token.token_type != :CloseParen
          end)

        if close.token_type != :CloseParen do
          raise "Formals should end with a closing bracket"
        end

        {formals, formals_tail}
    end
  end

  def build_expr_list(tokens, body_list) do
    {exp, [close | body_tail] = others} = parse_expr(tokens)

    cond do
      close.token_type == :CloseParen ->
        {body_list ++ [exp], others}

      true ->
        build_expr_list(others, body_list ++ [exp])
    end
  end
end
