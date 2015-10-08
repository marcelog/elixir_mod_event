defmodule FSModEvent.Test.Packet do
  use ExUnit.Case, async: true
  alias FSModEvent.Packet, as: Packet
  require Logger

  test "can parse auth/request" do
    {"", [p]} = Packet.parse read!("1.txt")
    assert p.type === "auth/request"
    refute p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{"Content-Type" => "auth/request"}
    assert p.length === 0
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === ""
  end

  test "can parse command/reply" do
    {"", [p]} = Packet.parse read!("2.txt")
    assert p.type === "command/reply"
    assert p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{
      "Reply-Text" => "+OK accepted",
      "Content-Type" => "command/reply"
    }
    assert p.length === 0
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === ""
  end

  test "can parse multiple" do
    {"", pkts} = Packet.parse read!("3.txt")
    assert length(pkts) === 2
    [p1, p2] = pkts
    assert p1.type === "text/event-plain"
    refute p1.success
    assert p1.headers_complete
    assert p1.payload_complete
    assert p1.complete
    refute p1.parse_error
    assert p1.headers === %{
      "Content-Type" => "text/event-plain",
      "Content-Length" => "555"
    }
    assert p1.length === 555
    assert is_nil p1.rest
    assert is_nil p1.job_id
    assert p1.payload === %{
      "Task-Runtime" => "1436033914",
      "Task-Group" => "core",
      "Task-Desc" => "heartbeat",
      "Task-ID" => "2",
      "Event-Sequence" => "1996",
      "Event-Calling-Line-Number" => "71",
      "Event-Calling-Function" => "switch_scheduler_execute",
      "Event-Calling-File" => "switch_scheduler.c",
      "Event-Date-Timestamp" => "1436033894106095",
      "Event-Date-GMT" => "Sat, 04 Jul 2015 18:18:14 GMT",
      "Event-Date-Local" => "2015-07-04 15:18:14",
      "FreeSWITCH-IPv6" => "::1",
      "FreeSWITCH-IPv4" => "192.168.1.102",
      "FreeSWITCH-Switchname" => "faulty.local",
      "FreeSWITCH-Hostname" => "faulty.local",
      "Core-UUID" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "Event-Name" => "RE_SCHEDULE"
    }

    assert p2.type === "text/event-plain"
    refute p2.success
    assert p2.headers_complete
    assert p2.payload_complete
    assert p2.complete
    refute p2.parse_error
    assert p2.headers === %{
      "Content-Type" => "text/event-plain",
      "Content-Length" => "554"
    }
    assert p2.length === 554
    assert is_nil p2.rest
    assert is_nil p2.job_id
    assert p2.payload === %{
      "Task-Runtime" => "1436033954",
      "Task-Group" => "core",
      "Task-Desc" => "check_ip",
      "Task-ID" => "3",
      "Event-Sequence" => "1997",
      "Event-Calling-Line-Number" => "71",
      "Event-Calling-Function" => "switch_scheduler_execute",
      "Event-Calling-File" => "switch_scheduler.c",
      "Event-Date-Timestamp" => "1436033894106095",
      "Event-Date-GMT" => "Sat, 04 Jul 2015 18:18:14 GMT",
      "Event-Date-Local" => "2015-07-04 15:18:14",
      "FreeSWITCH-IPv6" => "::1",
      "FreeSWITCH-IPv4" => "192.168.1.102",
      "FreeSWITCH-Switchname" => "faulty.local",
      "FreeSWITCH-Hostname" => "faulty.local",
      "Core-UUID" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "Event-Name" => "RE_SCHEDULE"
    }
  end

  test "can parse custom data" do
    {"", [p]} = Packet.parse read!("4.txt")
    assert p.type === "text/event-plain"
    refute p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{
      "Content-Type" => "text/event-plain",
      "Content-Length" => "654"
    }
    assert p.length === 654
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === %{
      "Content-Length" => "57",
      "Event-Sequence" => "4205",
      "Event-Calling-Line-Number" => "2209",
      "Event-Calling-Function" => "parse_command",
      "Event-Calling-File" => "mod_event_socket.c",
      "Event-Date-Timestamp" => "1436051526425813",
      "Event-Date-GMT" => "Sat, 04 Jul 2015 23:12:06 GMT",
      "Event-Date-Local" => "2015-07-04 20:12:06",
      "FreeSWITCH-IPv6" => "::1",
      "FreeSWITCH-IPv4" => "192.168.1.102",
      "FreeSWITCH-Switchname" => "faulty.local",
      "FreeSWITCH-Hostname" => "faulty.local",
      "Core-UUID" => "a95e64ec-df1f-48f4-acbf-34b4c359d747",
      "Event-Name" => "CUSTOM",
      "Event-UUID" => "ee38d831-c80a-4520-8249-7424fa353408",
      "hdr1" => "val1",
      "content-length" => "57",
      "Command" => "sendevent myeventito",
    }
    assert p.custom_payload === "this is a custom payload this is a custom payload oh yeah"
  end

  test "can parse multiple json" do
    # adding a \n here since is added by the text editor, while FS does not send it
    {"\n", pkts} = Packet.parse read!("1.json")
    assert length(pkts) === 2
    [p1, p2] = pkts
    assert p1.type === "text/event-json"
    refute p1.success
    assert p1.headers_complete
    assert p1.payload_complete
    assert p1.complete
    refute p1.parse_error
    assert p1.headers === %{
      "Content-Type" => "text/event-json",
      "Content-Length" => "593"
    }
    assert p1.length === 593
    assert is_nil p1.rest
    assert is_nil p1.job_id
    assert p1.payload === %{
      "Task-Runtime" => "1443694257",
      "Task-Group" => "mod_hash",
      "Task-Desc" => "limit_hash_cleanup",
      "Task-ID" => "3",
      "Event-Sequence" => "500540",
      "Event-Calling-Line-Number" => "71",
      "Event-Calling-Function" => "switch_scheduler_execute",
      "Event-Calling-File" => "switch_scheduler.c",
      "Event-Date-Timestamp" => "1443693357225307",
      "Event-Date-GMT" => "Thu, 01 Oct 2015 09:55:57 GMT",
      "Event-Date-Local" => "2015-10-01 11:55:57",
      "FreeSWITCH-IPv6" => "::1",
      "FreeSWITCH-IPv4" => "192.168.1.102",
      "FreeSWITCH-Switchname" => "orchestra6",
      "FreeSWITCH-Hostname" => "orchestra6",
      "Core-UUID" => "e613b7d4-66b3-11e5-aac9-a57c996c3705",
      "Event-Name" => "RE_SCHEDULE"
    }

    assert p2.type === "text/event-json"
    refute p2.success
    assert p2.headers_complete
    assert p2.payload_complete
    assert p2.complete
    refute p2.parse_error
    assert p2.headers === %{
      "Content-Type" => "text/event-json",
      "Content-Length" => "580"
    }
    assert p2.length === 580
    assert is_nil p2.rest
    assert is_nil p2.job_id
  end

  test "can parse custom data json" do
    {"\n", [p]} = Packet.parse read!("2.json")
    assert p.type === "text/event-json"
    refute p.success
    assert p.headers_complete
    assert p.payload_complete
    assert p.complete
    refute p.parse_error
    assert p.headers === %{
      "Content-Type" => "text/event-json",
      "Content-Length" => "691"
    }
    assert p.length === 691
    assert is_nil p.rest
    assert is_nil p.job_id
    assert p.payload === %{
      "Content-Length" => "57",
      "Event-Sequence" => "485377",
      "Event-Calling-Line-Number" => "2210",
      "Event-Calling-Function" => "parse_command",
      "Event-Calling-File" => "mod_event_socket.c",
      "Event-Date-Timestamp" => "1444136659462419",
      "Event-Date-GMT" => "Tue, 06 Oct 2015 13:04:19 GMT",
      "Event-Date-Local" => "2015-10-06 15:04:19",
      "FreeSWITCH-IPv6" => "::1",
      "FreeSWITCH-IPv4" => "192.168.1.102",
      "FreeSWITCH-Switchname" => "orchestra6",
      "FreeSWITCH-Hostname" => "orchestra6",
      "Core-UUID" => "3969ccf8-68fc-11e5-a15b-07aa2598e08f",
      "Event-Name" => "CUSTOM",
      "Event-UUID" => "c173a94e-6c2a-11e5-9d27-07aa2598e08f",
      "hdr" => "hdr1",
      "content-length" => "57",
      "Command" => "sendevent customevent",
    }
    assert p.custom_payload === "this is a custom payload this is a custom payload oh yeah"
  end

  defp read!(file) do
    File.read!("test/resources/#{file}")
  end
end
