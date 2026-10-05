open Lwt.Infix

(* A2A-server has to be spawned at: *)
let url = "http://localhost:3000/jsonrpc"

let () =
  let message =
    {
      A2a.Types.message_id = "ocaml-example-1";
      context_id = None;
      task_id = None;
      role = A2a.Types.User;
      parts =
        [
          {
            A2a.Types.content = A2a.Types.Text "Hello from OCaml";
            metadata = None;
            filename = None;
            media_type = None;
          };
        ];
      metadata = None;
      extensions = [];
      reference_task_ids = [];
    }
  in
  let params = A2a.Request.build_send_message_request message in
  Lwt_main.run
    ( A2a.Jsonrpc.send_rpc_message url (A2a.Jsonrpc.StringId "1") params
    >>= fun response ->
      match response with
      | A2a.Types.TaskResponse task ->
          Printf.printf "Task ID: %s\n" task.id;
          Printf.printf "Context ID: %s\n" task.context_id;
          Lwt.return_unit
      | A2a.Types.MessageResponse message ->
          Printf.printf "Message ID: %s\n" message.message_id;
          Lwt.return_unit )
