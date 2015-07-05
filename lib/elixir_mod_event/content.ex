defmodule FSModEvent.Content do
  @moduledoc """
  Parses the given payload.

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
  alias FSModEvent.Header, as: Header

  @doc """
  Will parse and return a payload according to the content type given.
  """
  @spec parse(String.t, char_list) :: term
  def parse("text/event-plain", data) do
    event_plain data, %{}
  end

  def parse(_, data), do: {data, nil}

  defp event_plain(data, acc) do
    case Header.parse data do
      {key, value, rest} ->
        acc = Map.put acc, key, URI.decode_www_form(value)
        case rest do
          [?\n|rest] -> {acc, rest}
          _ -> event_plain rest, acc
        end
      _error -> nil
    end
  end
end