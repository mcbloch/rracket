defmodule Token do
  defstruct [:token_type]

  @type token_type ::
          {:OpenParen}
          | {:CloseParen}
          | {:KwLambda}
          | {:KwIf}
          | {:KwDefine}
          | {:KwSet}
          | {:Num, number}
          | {:Bool, bool}
          | {:Identifier, String.t()}
end
