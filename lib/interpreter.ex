defmodule Interpreter do
  @moduledoc false

  def save_env(k, v) do
    # # IO.puts("Saving key value => #{k} : ")
    #    IO.inspect(v)
    Agent.update(:kv, fn map -> Map.put(map, k, v) end)
  end

  def get_env(k) do
    Agent.get(:kv, fn map -> Map.get(map, k) end)
  end

  def interpret(ast) do
    {:ok, _pid} = Agent.start_link(fn -> %{} end, name: :kv)

    interpret_(ast)
  end

  defp interpret_([h]), do: interpret_(h)

  defp interpret_([h | t]) do
    interpret_(h)
    interpret_(t)
  end

  defp interpret_(%Parser.NodeCall{} = node) do
    call_res =
      case node.operator do
        %Token{token_type: {:Identifier, ["print"]}} ->
          if length(node.operands) != 1 do
            raise "lmao, can you even code"
          end

          result = interpret_(hd(node.operands))

          IO.puts("> #{result}")
          nil

        %Token{token_type: {:Identifier, ["<="]}} ->
          if length(node.operands) != 2 do
            raise "you fucking wanker"
          end

          #          IO.inspect(node.operands)
          operands = node.operands |> Enum.map(&interpret_(&1))
          #          IO.inspect(node.operands)

          operands
          |> Enum.each(
            &if not is_number(&1) do
              raise "lmao you dumb bitch"
            end
          )

          [lefirst | [lesecond | _]] = operands
          lefirst <= lesecond

        %Token{token_type: {:Identifier, ["-"]}} ->
          if length(node.operands) != 2 do
            raise "you fucking wanker"
          end

          operands = node.operands |> Enum.map(&interpret_(&1))

          operands
          |> Enum.each(
            &if not is_number(&1) do
              raise "lmao you dumb bitch"
            end
          )

          [lefirst | [lesecond | _]] = operands
          lefirst - lesecond

        %Token{token_type: {:Identifier, ["+"]}} ->
          operands = node.operands |> Enum.map(&interpret_(&1))

          operands
          |> Enum.each(
            &if not is_number(&1) do
              raise "lmao you dumb bitch"
            end
          )

          operands |> Enum.sum()

        %Token{token_type: {:Identifier, [name | _]}} ->
          nodes = get_env(name)

          arg_names = nodes.formals |> Enum.map(&(&1.token_type |> elem(1) |> hd))
          arg_values = node.operands |> Enum.map(&interpret_(&1))

          prev_values = arg_names |> Enum.map(&get_env(&1))

          # # IO.puts("Saving")

          Enum.zip(arg_names, arg_values)
          |> Enum.each(fn {arg_name, value} ->
            save_env(arg_name, value)
          end)

          # # IO.puts("Identifier '#{name}' called.")
          res = interpret_(nodes.body)

          # # IO.puts("Lambda of function #{name} with n=#{hd(arg_values)} returned '#{res}'")

          # # IO.puts("Restoring")

          Enum.zip(arg_names, prev_values)
          |> Enum.each(fn {arg_name, value} ->
            save_env(arg_name, value)
          end)

          res
      end

    # # IO.puts("Call result: #{call_res}")
    call_res
  end

  defp interpret_(%Parser.NodeDefine{} = node) do
    name = node.variable.token_type |> elem(1) |> hd
    expr = node.expression
    save_env(name, expr)
  end

  defp interpret_(%Parser.NodeLambda{} = node) do
    node
  end

  defp interpret_(%Parser.NodeIdentifier{} = node) do
    name = hd(elem(node.v.token_type, 1))
    value = get_env(name)
    # # IO.puts("resolving identifier #{name} to:")
    #    IO.inspect(value)
    interpret_(value)
  end

  defp interpret_(%Parser.NodeConst{} = node) do
    # # IO.puts("Resolving const: #{elem(node.v.token_type, 1)}")
    elem(node.v.token_type, 1)
  end

  defp interpret_(%Parser.NodeIf{} = node) do
    # IO.puts("IF")
    # IO.puts(get_env("n"))
    result = interpret_(node.test)

    if result do
      #      IO.inspect(node.consequent)
      res = interpret_(node.consequent)
      # IO.puts("If returns ")
      #      IO.inspect(res)
      res
    else
      if is_nil(node.alternate) do
        IO.inspect("Going into nil alternate")
        nil
      else
        res = interpret_(node.alternate)
        # IO.puts("Else returns ")
        #        IO.inspect(res)
        res
      end
    end
  end

  defp interpret_(num) when is_number(num), do: num
end
