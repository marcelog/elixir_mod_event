defmodule FSModEvent.Header do
  @moduledoc """
  Header parsing functions.

  Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  """

  @doc """
  Given a line terminated in \n tries to parse a header in the form:
  Key: Value\n
  """
  @spec parse(char_list) :: {String.t, String.t, char_list} | :error
  def parse(char_list) do
    char_list |> parse_key |> parse_value |> normalize
  end

  defp parse_key(char_list) do
    parse_key char_list, []
  end

  defp parse_key([c, ?:, 32|rest], acc) do
    {Enum.reverse([c|acc]), rest}
  end

  defp parse_key([c|rest], acc) do
    parse_key rest, [c|acc]
  end

  defp parse_key(_, _), do: :error

  defp parse_value({key, rest}) do
    parse_value {key, rest}, []
  end

  defp parse_value(error), do: error

  defp parse_value({key, [?\n|rest]}, acc) do
    {key, Enum.reverse(acc), rest}
  end

  defp parse_value({key, [c|rest]}, acc) do
    parse_value {key, rest}, [c|acc]
  end

  defp parse_value(_, _), do: :error

  defp normalize({key, value, rest}) do
    {String.downcase(to_string(key)), to_string(value), rest}
  end

  defp normalize(error), do: error
end
