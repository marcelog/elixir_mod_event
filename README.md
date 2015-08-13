[![Build Status](https://travis-ci.org/marcelog/elixir_mod_event.svg)](https://travis-ci.org/marcelog/elixir_mod_event)

# elixir_mod_event
Elixir client for the [FreeSWITCH mod_event_socket](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket).

It also supports the [mod_erlang_event](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event).

----

# Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:elixir_mod_event, "~> 0.0.3"}]
end
```
Then run mix deps.get to install it.

----

# Documentation

Feel free to take a look at the [documentation](http://hexdocs.pm/elixir_mod_event/)
served by hex.pm or the source itself to find more.

----

# Inbound Mode (TCP connection)

## Starting a TCP connection
To connect to FreeSWITCH just start a [Connection](https://github.com/marcelog/elixir_mod_event/blob/master/lib/elixir_mod_event/connection.ex),
which is just a [GenServer](http://elixir-lang.org/docs/v1.0/elixir/GenServer.html) that you
can plug into your own supervisor tree.
```elixir
> alias FSModEvent.Connection, as: C
> C.start :connection_name, fs_host, fs_port, fs_password
{:ok, #PID<0.158.0>}
```

You can also start and link the connection:
```elixir
> C.start :connection_name, fs_host, fs_port, fs_password
{:ok, #PID<0.159.0>}
```

## Results
When executing a command (either in foreground or background) or receiving events,
the result will be a [Packet](https://github.com/marcelog/elixir_mod_event/blob/master/lib/elixir_mod_event/packet.ex),
with a structure with some fields of interest:

 * **success**: Boolean. When executing foreground commands will be true if the command
 was executed successfuly.
 * **type**: String. The type of the packet (e.g: "text/event-plain", "command/reply", etc).
 * **payload**: Map or String. Depends on the type of the packet.
 * **length**: Payload length, useful when the payload is a string.
 * **job_id**: String. May contain a job id, related to a response or an event.
 * **headers**: Map. Packet headers.
 * **custom_payload**: String. May contain additional payload, depends on the packet and command sent/received.

### Receiving events

To receive events register processes with a filter function like this:
```elixir
> C.start_listening :fs1
```

The default filter function will let all events pass through to the process, but
you can specify a custom filter function:
```elixir
> C.start_listening :fs1, fn(pkt) -> pkt.payload["event-name"] === "HEARTBEAT" end
```

To unregister the listener process:
```elixir
> C.stop_listening :fs1
```

**NOTE**: The caller process will be monitored and auto-unregister when the registered process dies.

## Examples

### [api](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-api)
Sends a [command](https://freeswitch.org/confluence/display/FREESWITCH/mod_commands).

```elixir
> C.api :fs1, "host_lookup", "google.com"
%FSModEvent.Packet{
  payload: '173.194.42.78',
  ...
}
```

### [bgapi](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-bgapi)
Like `api` but runs the command without blocking the process. The calling process will
receive a message with the result of the command. Be sure to subscribe to the
[BACKGROUND_JOB](https://freeswitch.org/confluence/display/FREESWITCH/Event+List#EventList-Otherevents) event.

```elixir
> C.event :fs1, "BACKGROUND_JOB"
> C.bgapi :fs1, "md5", "some_data"
"b857e1dd-e4de-424e-9ff6-8e05e9a076d9"
> flush
{:fs_job_result, "b857e1dd-e4de-424e-9ff6-8e05e9a076d9", %FSModEvent.Packet{
  custom_payload: '0d9247cbce34aba4aca8d5c887a0f0a4',
  ...
}}
```

### [linger](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-linger)
```elixir
> C.linger :fs1
```

### [nolinger](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-nolinger)
```elixir
> C.nolinger :fs1
```

### [event](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-event)
```elixir
> C.event :fs1, "all"
> C.event :fs1, "CUSTOM", "conference::maintenance"
```

### [myevents](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-SpecialCase-'myevents')
```elixir
> C.myevents :fs1, "e96b78d8-1dc2-4634-84c4-58366f1a92b1"
```

### [divert_events](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-divert_events)
```elixir
> C.enable_divert_events :fs1
> C.disable_divert_events :fs1
```

### [filter](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-filter)
```elixir
> C.filter :fs1, "Event-Name", "CHANNEL_EXECUTE"
```

### [filter_delete](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-filterdelete)
```elixir
> C.filter_delete :fs1, "Event-Name", "CHANNEL_EXECUTE"
```

### [sendevent](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-sendevent)
```elixir
> C.sendevent :fs1, "custom_event", [{"header1", "value1"}], "custom payload"
```

### [sendmsg](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-sendmsg)
```elixir
> C.sendmsg_exec :fs1, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "uuid_answer", "e96b78d8-1dc2-4634-84c4-58366f1a92b1"
> C.sendmsg_hangup :fs1, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", 16
> C.sendmsg_unicast :fs1, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "tcp", "native", "127.0.0.1", 8025, "127.0.0.1", 8026
> C.sendmsg_nomedia :fs1, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "info"
```

### [exit](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-exit)
```elixir
> C.exit :fs1
```

### [log](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-log)
```elixir
> C.log :fs1, "debug"
```

### [nolog](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-nolog)
```elixir
> C.nolog :fs1
```

### [nixevent](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-nixevent)
```elixir
> C.nixevent :fs1, "all"
```

### [noevents](https://freeswitch.org/confluence/display/FREESWITCH/mod_event_socket#mod_event_socket-noevents)
```elixir
> C.noevents :fs1
```

----

# Inbound Mode (Erlang node connection)

To "talk" to the FreeSWITCH erlang node, use the [Erlang](https://github.com/marcelog/elixir_mod_event/blob/master/lib/elixir_mod_event/erlang.ex) module:

```elixir
> alias FSModEvent.Erlang, as: E
> node = :"freeswitch@host.local"
```

### [api](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-api)
Sends a [command](https://freeswitch.org/confluence/display/FREESWITCH/mod_commands).

```elixir
> E.api node, "host_lookup", "google.com"
"173.194.42.82"
```

### [bgapi](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-bgapi)
Like `api` but runs the command without blocking the process. The caller process will
receive a message with a tuple like this:

```elixir
  {:fs_job_result, job_id, status, result}
```

  Where:

```elixir
  job_id :: String.t

  status :: :ok | :error

  result :: :timeout | String.t
```

```elixir
> E.bgapi node, "md5", "some_data"
"4a41cfc1-d9b7-4966-95d0-5de5ec690a07"

> flush
{:fs_job_result, "4a41cfc1-d9b7-4966-95d0-5de5ec690a07", :ok,
 "0d9247cbce34aba4aca8d5c887a0f0a4"}
```

### [register_event_handler](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-register_event_handler)
```elixir
> E.register_event_handler node
```

### [event](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-event)
```elixir
> E.event node, "all"
> E.event node, "CUSTOM", "conference::maintenance"
```

### [nixevent](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-nixevent)
```elixir
> E.nixevent node, "all"
```

### [noevents](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-noevents)
```elixir
> E.noevents node
```

### [register_log_handler](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-register_log_handler)
```elixir
> E.register_log_handler node
```

### [set_log_level](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-set_log_level)
```elixir
> E.set_log_level node, "debug"
```

### [nolog](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-nolog)
```elixir
> E.nolog node
```

### [exit](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-exit)
```elixir
> E.exit node
```

### [sendmsg](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-sendmsg)
```elixir
> E.sendmsg_exec node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "uuid_answer", "e96b78d8-1dc2-4634-84c4-58366f1a92b1"
> E.sendmsg_hangup node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", 16
> E.sendmsg_unicast node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "tcp", "native", "127.0.0.1", 8025, "127.0.0.1", 8026
> E.sendmsg_nomedia node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", "info"
```

### [pid](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-getpid)
```elixir
> E.pid node
```

### [handlecall](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-handlecall)
```elixir
> E.handlecall node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1"
> E.handlecall node, "e96b78d8-1dc2-4634-84c4-58366f1a92b1", :my_call_handler
```

### Configuration hooks
You can also configure FreeSWITCH by sending and receiving regular erlang messages by
binding to the needed configuration sections. See [XML Search Bindings](https://freeswitch.org/confluence/display/FREESWITCH/mod_erlang_event#mod_erlang_event-XMLsearchbindings).

The format and sections correspond to the ones supported by [mod_xml_curl](https://freeswitch.org/confluence/display/FREESWITCH/mod_xml_curl).

```elixir
# Bind to the "directory" section
> E.config_bind node, "directory"

# Sample XML text
> xml = "<?xml version='1.0' en ... "

# After a configuration message is received, a reply can be sent.
> receive do
    {:fetch, :directory, "domain", "name", domain_name, uuid, headers} ->
      E.config_reply node, uuid, xml
  after 10 -> :ok
  end
```

----

# License
The source code is released under Apache 2 License.

Check [LICENSE](https://github.com/marcelog/elixir_mod_event/blob/master/LICENSE) file for more information.

