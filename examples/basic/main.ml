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
    >>= fun (response, response_body) ->
      Cohttp_lwt.Body.to_string response_body >>= fun response_body ->
      Printf.printf "HTTP status: %s\n"
        (Cohttp.Code.string_of_status (Cohttp.Response.status response));
      Printf.printf "Response:\n%s\n" response_body;
      Lwt.return_unit )
