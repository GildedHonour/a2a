open Lwt.Infix

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
  let params =
    A2a.Request.build_send_message_request message
  in
  let params_json =
    A2a.Jsonrpc.send_message_params_to_json params
  in
  let request =
    A2a.Jsonrpc.build_rpc_request
      (A2a.Jsonrpc.StringId "1")
      A2a.Jsonrpc.SendMessage
      ~params:params_json
  in
  let body =
    A2a.Jsonrpc.request_to_json request
    |> Yojson.Safe.to_string
  in
  let uri = Uri.of_string "http://localhost:3000/jsonrpc" in
  let headers =
    Cohttp.Header.init_with "content-type" "application/json"
  in
  Cohttp_lwt_unix.Client.post
    ~headers
    ~body:(Cohttp_lwt.Body.of_string body)
    uri
  >>= fun (response, response_body) ->
  Cohttp_lwt.Body.to_string response_body >>= fun response_body ->
  Printf.printf "HTTP status: %s\n" (Cohttp.Code.string_of_status (Cohttp.Response.status response));
  Printf.printf "Response:\n%s\n" response_body;
  Lwt.return_unit
