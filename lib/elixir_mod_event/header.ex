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
  @spec parse(String.t) :: {String.t, String.t, String.t} | :error
  def parse(string) do
    case :re.run string, "^([^:]*): ([^\n]*)\n", [{:capture, :all, :binary}] do
      {:match, [hv, h, v]} ->
        l = byte_size hv
        rest = :binary.part string, l, (byte_size(string) - l)
        {h, v, rest}
      _ -> :error
    end
  end
end
