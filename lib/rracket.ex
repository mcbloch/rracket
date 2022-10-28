defmodule Rracket do
  @moduledoc """
  Documentation for `Rracket`.
  """

  @spec load(String.t()) :: {:ok}
  def load(source_file) do
    case File.read(source_file) do
      {:ok, value} ->
        Lexer.lex(value)
        |> IO.inspect()
        |> Parser.parse()
        |> IO.inspect()
        |> Interpreter.interpret()
        |> IO.inspect()

      {:error, err} ->
        # IO.puts("ohno.jpg")
    end
  end
end
