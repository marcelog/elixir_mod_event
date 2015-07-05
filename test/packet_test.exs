defmodule FSModEvent.Test.Packet do
  use ExUnit.Case, async: true
  alias FSModEvent.Packet, as: Packet
  require Logger

  test "can parse auth/request" do
    {'', [p]} = Packet.parse read!("1.txt")
    assert p.type === "auth/request"
    refute p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{"content-type" => "auth/request"}
    assert p.length === 0
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === ''
  end

  test "can parse command/reply" do
    {'', [p]} = Packet.parse read!("2.txt")
    assert p.type === "command/reply"
    assert p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{
      "reply-text" => "+OK accepted",
      "content-type" => "command/reply"
    }
    assert p.length === 0
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === ''
  end

  test "can parse multiple" do
    {'', pkts} = Packet.parse read!("3.txt")
    assert length(pkts) === 2
    [p1, p2] = pkts
    assert p1.type === "text/event-plain"
    refute p1.success
    assert p1.headers_complete
    assert p1.payload_complete
    assert p1.complete
    refute p1.parse_error
    assert p1.headers === %{
      "content-type" => "text/event-plain",
      "content-length" => "555"
    }
    assert p1.length === 555
    assert is_nil p1.rest
    assert is_nil p1.job_id
    assert p1.payload === %{
      "task-runtime" => "1436033914",
      "task-group" => "core",
      "task-desc" => "heartbeat",
      "task-id" => "2",
      "event-sequence" => "1996",
      "event-calling-line-number" => "71",
      "event-calling-function" => "switch_scheduler_execute",
      "event-calling-file" => "switch_scheduler.c",
      "event-date-timestamp" => "1436033894106095",
      "event-date-gmt" => "Sat, 04 Jul 2015 18:18:14 GMT",
      "event-date-local" => "2015-07-04 15:18:14",
      "freeswitch-ipv6" => "::1",
      "freeswitch-ipv4" => "192.168.1.102",
      "freeswitch-switchname" => "faulty.local",
      "freeswitch-hostname" => "faulty.local",
      "core-uuid" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "event-name" => "RE_SCHEDULE"
    }

    assert p2.type === "text/event-plain"
    refute p2.success
    assert p2.headers_complete
    assert p2.payload_complete
    assert p2.complete
    refute p2.parse_error
    assert p2.headers === %{
      "content-type" => "text/event-plain",
      "content-length" => "554"
    }
    assert p2.length === 554
    assert is_nil p2.rest
    assert is_nil p2.job_id
    assert p2.payload === %{
      "task-runtime" => "1436033954",
      "task-group" => "core",
      "task-desc" => "check_ip",
      "task-id" => "3",
      "event-sequence" => "1997",
      "event-calling-line-number" => "71",
      "event-calling-function" => "switch_scheduler_execute",
      "event-calling-file" => "switch_scheduler.c",
      "event-date-timestamp" => "1436033894106095",
      "event-date-gmt" => "Sat, 04 Jul 2015 18:18:14 GMT",
      "event-date-local" => "2015-07-04 15:18:14",
      "freeswitch-ipv6" => "::1",
      "freeswitch-ipv4" => "192.168.1.102",
      "freeswitch-switchname" => "faulty.local",
      "freeswitch-hostname" => "faulty.local",
      "core-uuid" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "event-name" => "RE_SCHEDULE"
    }
  end

  test "can parse custom data" do
    {'', [p]} = Packet.parse read!("4.txt")
    assert p.type === "text/event-plain"
    refute p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{
      "content-type" => "text/event-plain",
      "content-length" => "654"
    }
    assert p.length === 654
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === %{
      "content-length" => "57",
      "event-sequence" => "4205",
      "event-calling-line-number" => "2209",
      "event-calling-function" => "parse_command",
      "event-calling-file" => "mod_event_socket.c",
      "event-date-timestamp" => "1436051526425813",
      "event-date-gmt" => "Sat, 04 Jul 2015 23:12:06 GMT",
      "event-date-local" => "2015-07-04 20:12:06",
      "freeswitch-ipv6" => "::1",
      "freeswitch-ipv4" => "192.168.1.102",
      "freeswitch-switchname" => "faulty.local",
      "freeswitch-hostname" => "faulty.local",
      "core-uuid" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "event-name" => "CUSTOM",
      "event-uuid" => "ee38d831-c80a-4520-8249-7424fa353408",
      "hdr1" => "val1",
      "content-length" => "57",
      "command" => "sendevent myeventito",
    }
    assert p.custom_payload === 'this is a custom payload this is a custom payload oh yeah'
  end

  defp read!(file) do
    to_char_list File.read!("test/resources/#{file}")
  end
end
