# A2A OCaml SDK [WIP]
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

An OCaml library that runs agentic applications as A2AServers following the [Agent2Agent (A2A) Protocol](https://a2a-protocol.org).

## Usage

A basic example:

```ocaml
let () =
  let client =
    A2a.Client.create
      ~base_url:"https://agent.example.com"
      ()
  in
  let message =
    A2a.Request.Message.create
      ~role:A2a.Types.User
      ~text:"What is the weather in London?"
      ()
  in
  match A2a.Client.send_message client message with
  | A2a.Types.Message message ->
      Printf.printf "Agent response: %s\n" (A2a.Types.Message.text message)
  | A2a.Types.Task task ->
      Printf.printf "Task created: %s\n" task.id
```

### Sending a message

A message may contain multiple parts. For a simple text message:

```ocaml
let message =
  A2a.Request.Message.create
    ~role:A2a.Types.User
    ~text:"Analyse this document and summarise its contents."
    ()
```

The message may then be sent through the client:

```ocaml
let response =
  A2a.Client.send_message client message
```

An agent may respond immediately with a message:

```ocaml
match response with
| A2a.Types.Message message ->
    Printf.printf
      "Agent replied: %s\n"
      (A2a.Types.Message.text message)
| A2a.Types.Task task ->
    Printf.printf
      "The agent created task %s\n"
      task.id
```

A `Task` represents a unit of work that may continue beyond the initial request; it's monitored and retrieved through the client.

### Creating a client

The client is configured with the A2A agent endpoint:

```ocaml
let client =
  A2a.Client.create
    ~base_url:"https://agent.example.com"
    ()
```

An application may construct a client with an authentication token:

```ocaml
let client =
  A2a.Client.create
    ~base_url:"https://agent.example.com"
    ~bearer_token:"..."
    ()
```


### Tasks

When an agent performs a long-running operation, `send_message` may return a task:

```ocaml
match A2a.Client.send_message client message with
| A2a.Types.Message message ->
    Printf.printf
      "Agent replied immediately: %s\n"
      (A2a.Types.Message.text message)
| A2a.Types.Task task ->
    Printf.printf
      "Task ID: %s\n"
      task.id;
    Printf.printf
      "Context ID: %s\n"
      task.context_id
```

The task may then be queried:

```ocaml
let task =
  A2a.Client.get_task
    client
    ~task_id:task_id
    ()
```

The application may inspect the current status of it:

```ocaml
match task.status.state with
| A2a.Types.Working ->
    print_endline "The agent is still working"
| A2a.Types.Completed ->
    print_endline "The task has completed"
| A2a.Types.Failed ->
    print_endline "The task failed"
| _ ->
    print_endline "The task has another state"
```

### Streaming

For agents that support streaming:

```ocaml
A2a.Client.send_message_stream
  client
  message
  ~on_event:(function
    | A2a.Types.Task_status_update event ->
        Printf.printf
          "Task state: %s\n"
          (A2a.Types.Task_state.to_string event.status.state)
    | A2a.Types.Task_artifact_update event ->
        Printf.printf
          "Artifact: %s\n"
          event.artifact.artifact_id)
```

### Lower-level APIs

An application which implements its own transport may need to construct a JSON-RPC request directly:

```ocaml
let request =
  A2a.Jsonrpc.send_message_request
    (A2a.Jsonrpc.String_id "request-1")
    params
```

and serialise it:

```ocaml
let json =
  A2a.Jsonrpc.request_to_json request
```



# Author
Alex Maslakoff

# License
Apache-2.0.
