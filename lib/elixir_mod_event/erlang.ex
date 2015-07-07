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
  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendevent
  """
  @spec sendevent(node, String.t, [{String.t, String.t}]) :: :ok | no_return
  def sendevent(node, event, headers) do
    run node, :sendevent, {:sendevent, event, headers}
  end

  @doc """
  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendmsg
  """
  @spec sendmsg_exec(
    node, String.t, String.t, String.t, Integer.t
  ) :: :ok | no_return
  def sendmsg_exec(name, uuid, command, args \\ "", loops \\ 1) do
    sendmsg name, uuid, 'execute', [
      {'execute-app-name', to_char_list(command)},
      {'execute-app-arg', to_char_list(args)},
      {'loops', to_char_list(loops)}
    ]
  end

  @doc """
  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendmsg
  """
  @spec sendmsg_hangup(node, String.t, Integer.t) :: :ok | no_return
  def sendmsg_hangup(name, uuid, cause \\ 16) do
    sendmsg name, uuid, 'hangup', [{'hangup-cause', to_char_list(cause)}]
  end

  @doc """
  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendmsg
  """
  @spec sendmsg_unicast(
    node, String.t, String.t, String.t,
    String.t, Integer.t, String.t, Integer.t
  ) :: FSModEvent.Packet.t
  def sendmsg_unicast(
    name, uuid, transport \\ "tcp", flags \\ "native",
    local_ip \\ "127.0.0.1", local_port \\ 8025,
    remote_ip \\ "127.0.0.1", remote_port \\ 8026
  ) do
    sendmsg name, uuid, 'unicast', [
      {'local-ip', to_char_list(local_ip)},
      {'local-port', to_char_list(local_port)},
      {'remote-ip', to_char_list(remote_ip)},
      {'remote-port', to_char_list(remote_port)},
      {'transport', to_char_list(transport)},
      {'flags', to_char_list(flags)}
    ]
  end

  @doc """
  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendmsg
  """
  @spec sendmsg_nomedia(node, String.t, String.t) :: FSModEvent.Packet.t
  def sendmsg_nomedia(node, uuid, info \\ "") do
    sendmsg node, uuid, :nomedia, [{'nomedia-uuid', to_char_list(info)}]
  end

  @doc """
  Binds the caller process as a configuration provider for the given
  configuration section. The sections are the same as for mod_xml_curl, see:
  https://freeswitch.org/confluence/display/FREESWITCH/mod_xml_curl.

  You will receive messages of the type:

  {fetch, <Section>, <Tag>, <Key>, <Value>, <FetchID>, <Params>}

  Where FetchID is the ID you received in the request and XMLString is the XML
  reply you want to send. FetchID and XML can be binaries or strings.

  To tell the switch to take some action, send back a reply of the format:
  {fetch_reply, <FetchID>, <XML>}

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-XMLsearchbindings
  """
  @spec config_bind(node, String.t) :: :ok | no_return
  def config_bind(node, type) do
    run node, :bind, {:bind, String.to_atom(type)}
  end

  @doc """
  Sends an XML in response to a configuration message (see config_bind). The
  XML should be the same as the one supported by mod_xml_curl, see:
  https://freeswitch.org/confluence/display/FREESWITCH/mod_xml_curl.

  See: https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-XMLsearchbindings
  """
  @spec config_reply(node, String.t, String.t) :: :ok | no_return
  def config_reply(node, fetch_id, xml) do
    run node, :send, {:fetch_reply, fetch_id, xml}
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

  defp sendmsg(node, uuid, command, headers) do
    headers = [{'call-command', command}|headers]
    run node, :sendmsg, {:sendmsg, to_char_list(uuid), headers}
  end

  defp run(node, command, payload \\ nil, timeout \\ @timeout) do
    payload = if is_nil payload do
      command
    else
      payload
    end
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
