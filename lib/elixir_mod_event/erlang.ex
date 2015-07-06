defmodule FSModEvent.Erlang do
  @moduledoc """
  Interface to mod_erlang_event.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event

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
  defmodule Error do
    defexception message: "default message"
  end

  require Logger
  @timeout 5000

  @doc """
  Runs an API command in foreground.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-api
  """
  @spec api(node, String.t, String.t) :: String.t | no_return
  def api(node, command, args \\ "") do
    run node, :api, {:api, String.to_atom(command), args}
  end

  @doc """
  Runs an API command in background. Returns a job id. The caller process will
  receive a message with a tuple like this:
  {:fs_job_result, job_id, status, result}

  Where:

  job_id :: String.t
  status :: :ok | :error
  result :: :timeout | String.t

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-bgapi
  """
  @spec bgapi(node, String.t, String.t) :: String.t | no_return
  def bgapi(node, command, args \\ "", timeout \\ @timeout) do
    caller = self
    spawn fn ->
      job_id = run node, :bgapi, {:bgapi, String.to_atom(command), args}
      send caller, {:fs_job_id, job_id}
      receive do
        {status, ^job_id, x} ->
          status = if status === :bgok do
            :ok
          else
            :error
          end
          send caller, {:fs_job_result, job_id, status, x}
      after timeout ->
        send caller, {:fs_job_result, job_id, :error, :timeout}
      end
    end
    receive do
      {:fs_job_id, job_id} -> job_id
    end
  end

  @doc """
  Registers the caller process as a log handler. Will receive all logs as
  messages.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-register_log_handler
  """
  @spec register_log_handler(node) :: :ok | no_return
  def register_log_handler(node) do
    run node, :foo, :register_log_handler
  end

  @doc """
  Subscribe to an event.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-event
  """
  @spec event(node, String.t, String.t) :: :ok | no_return
  def event(node, event, value \\ nil) do
    if is_nil value do
      run node, :foo, {:event, String.to_atom(event)}
    else
      run node, :foo, {:event, String.to_atom(event), String.to_atom(value)}
    end
  end

  @doc """
  Unsubscribes from an event.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-nixevent
  """
  @spec nixevent(node, String.t, String.t) :: :ok | no_return
  def nixevent(node, event, value \\ nil) do
    if is_nil value do
      run node, :foo, {:nixevent, String.to_atom(event)}
    else
      run node, :foo, {:nixevent, String.to_atom(event), String.to_atom(value)}
    end
  end

  @doc """
  Registers the caller process as an event handler. Will receive all events as
  messages.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-register_event_handler
  """
  @spec register_event_handler(node) :: :ok | no_return
  def register_event_handler(node) do
    run node, :foo, :register_event_handler
  end

  @doc """
  Changes the log level.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-set_log_level
  """
  @spec set_log_level(node, String.t) :: :ok | no_return
  def set_log_level(node, level) do
    run node, :foo, {:set_log_level, String.to_atom(level)}
  end

  @doc """
  Disables logging.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-nolog
  """
  @spec nolog(node) :: :ok | no_return
  def nolog(node) do
    run node, :nolog
  end

  @doc """
  Closes the connection.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-exit
  """
  @spec exit(node) :: :ok | no_return
  def exit(node) do
    run node, :exit
  end

  @doc """
  Returns the fake pid of the "erlang process" running in the freeswitch erlang
  node.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-getpid
  """
  @spec pid(atom) :: pid | no_return
  def pid(node) do
    run node, :getpid
  end

  defp run(node, command, payload \\ nil, timeout \\ @timeout) do
    payload = if is_nil payload do
      command
    else
      payload
    end
    Logger.debug "sending: #{inspect {command, node}}"
    send {command, node}, payload
    receive do
      {:ok, x} -> x
      :ok -> :ok
      {:error, x} -> raise FSModEvent.Erlang.Error, message: "#{inspect x}"
      :error -> raise FSModEvent.Erlang.Error, message: "unknown error"
    after timeout ->
      raise FSModEvent.Erlang.Error, message: "timeout"
    end
  end
end
