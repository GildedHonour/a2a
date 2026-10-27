open Lwt.Infix

let protocol_version_header = "A2A-Version"
let protocol_version_header_value = "1.0"

type id =
  | StringId of string
  | IntId of int

type method_ =
  | SendMessage
  | SendStreamingMessage
  | GetTask
  | ListTasks
  | CancelTask
  | SubscribeToTask
  | CreateTaskPushNotificationConfig
  | GetTaskPushNotificationConfig
  | ListTaskPushNotificationConfigs
  | DeleteTaskPushNotificationConfig
  | GetExtendedAgentCard

type request = {
  jsonrpc : string;
  id : id;
  method_ : method_;
  params : Yojson.Safe.t option;
}

let build_rpc_request ?params id method_ =
  { jsonrpc = "2.0"; id; method_; params }

type rpc_error = {
  code : int;
  message : string;
  data : Yojson.Safe.t option;
}

exception HttpError of int * string
exception RpcError of rpc_error

let error_to_json (rpc_error : rpc_error) =
  let fields0 =
    (* TODO
        [ ("code", `Int rpc_error.code); ("message", `String rpc_error.message2) ]
      *)
    [ ("code", `Int rpc_error.code); ("message", `String rpc_error.message) ]
  in
  let fields1 =
    match rpc_error.data with
    | Some data ->
        ("data", data) :: fields0
    | None ->
        fields0
  in
  `Assoc (List.rev fields1)

let send_message_params_to_json (params : Request.send_message_request) =
  let fields0 = [ ("message", Json.message_to_json params.message) ] in
  let fields1 =
    match params.configuration with
    | Some value ->
        (* ("configuration", value) :: fields0 *)
        ("configuration", Json.send_message_configuration_to_json value)
        :: fields0
    | None ->
        fields0
  in
  let fields2 =
    match params.metadata with
    | Some value ->
        ("metadata", `Assoc value) :: fields1
    | None ->
        fields1
  in
  `Assoc (List.rev fields2)

let id_to_json = function
  | StringId value ->
      `String value
  | IntId value ->
      `Int value

let method_to_string = function
  | SendMessage ->
      "SendMessage"
  | SendStreamingMessage ->
      "SendStreamingMessage"
  | GetTask ->
      "GetTask"
  | ListTasks ->
      "ListTasks"
  | CancelTask ->
      "CancelTask"
  | SubscribeToTask ->
      "SubscribeToTask"
  | CreateTaskPushNotificationConfig ->
      "CreateTaskPushNotificationConfig"
  | GetTaskPushNotificationConfig ->
      "GetTaskPushNotificationConfig"
  | ListTaskPushNotificationConfigs ->
      "ListTaskPushNotificationConfigs"
  | DeleteTaskPushNotificationConfig ->
      "DeleteTaskPushNotificationConfig"
  | GetExtendedAgentCard ->
      "GetExtendedAgentCard"

type response =
  | Result of {
      jsonrpc : string;
      id : id;
      result : Yojson.Safe.t;
    }
  | Error of {
      jsonrpc : string;
      id : id option;
      error : rpc_error;
    }

let request_to_json req =
  let fields =
    [
      ("jsonrpc", `String req.jsonrpc);
      ("id", id_to_json req.id);
      ("method", `String (method_to_string req.method_));
    ]
  in
  let fields =
    match req.params with
    | Some params ->
        ("params", params) :: fields
    | None ->
        fields
  in
  `Assoc (List.rev fields)

let response_to_json = function
  | Result { jsonrpc; id; result } ->
      `Assoc
        [
          ("jsonrpc", `String jsonrpc); ("id", id_to_json id); ("result", result);
        ]
  | Error { jsonrpc; id; error } ->
      let fields =
        [ ("jsonrpc", `String jsonrpc); ("error", error_to_json error) ]
      in
      let fields =
        match id with
        | Some id ->
            ("id", id_to_json id) :: fields
        | None ->
            fields
      in
      `Assoc (List.rev fields)

let send_message_response_of_json json =
  let fields =
    match json with
    | `Assoc fields ->
        fields
    | _ ->
        raise (Json.DecodeError "SendMessage result is not an object")
  in
  match (List.assoc_opt "task" fields, List.assoc_opt "message" fields) with
  | Some task, None ->
      Types.TaskResponse (Json.task_of_json task)
  | None, Some message ->
      Types.MessageResponse (Json.message_of_json message)
  | Some _, Some _ ->
      raise
        (Json.DecodeError "SendMessage result contains both task and message")
  | None, None ->
      raise
        (Json.DecodeError "SendMessage result contains neither task nor message")

let rpc_error_of_json value =
  let fields =
    match value with
    | `Assoc fields ->
        fields
    | _ ->
        raise (Json.DecodeError "JSON-RPC error is not an object")
  in
  let code =
    match List.assoc_opt "code" fields with
    | Some (`Int value) ->
        value
    | Some _ ->
        raise (Json.DecodeError "JSON-RPC error code is not an integer")
    | None ->
        raise (Json.DecodeError "missing JSON-RPC error code")
  in
  let message =
    match List.assoc_opt "message" fields with
    | Some (`String value) ->
        value
    | Some _ ->
        raise (Json.DecodeError "JSON-RPC error message is not a string")
    | None ->
        raise (Json.DecodeError "missing JSON-RPC error message")
  in
  let data = List.assoc_opt "data" fields in
  { code; message; data }

let send_rpc_message url id params =
  let request =
    build_rpc_request
      ~params:(send_message_params_to_json params)
      id SendMessage
  in
  let body = Yojson.Safe.to_string (request_to_json request) in
  let headers =
    Cohttp.Header.of_list
      [ ("Content-Type", "application/json"); ("A2A-Version", "1.0") ]
  in
  Cohttp_lwt_unix.Client.post ~headers
    ~body:(Cohttp_lwt.Body.of_string body)
    (Uri.of_string url)
  >>= fun (response, response_body) ->
  Cohttp_lwt.Body.to_string response_body >>= fun response_body ->
  let status_code =
    Cohttp.Code.code_of_status (Cohttp.Response.status response)
  in
  let value =
    try Yojson.Safe.from_string response_body with
    | Yojson.Json_error message ->
        raise (Json.DecodeError message)
  in
  let fields =
    match value with
    | `Assoc fields ->
        fields
    | _ ->
        raise (Json.DecodeError "JSON-RPC response is not an object")
  in
  let version =
    match List.assoc_opt "jsonrpc" fields with
    | Some (`String version) ->
        version
    | Some _ ->
        raise (Json.DecodeError "JSON-RPC version is not a string")
    | None ->
        raise (Json.DecodeError "missing JSON-RPC version")
  in
  if version <> "2.0" then
    raise (Json.DecodeError "unsupported JSON-RPC version");
  let expected_id =
    match id with
    | StringId value ->
        `String value
    | IntId value ->
        `Int value
  in
  (match List.assoc_opt "id" fields with
  | Some response_id when response_id = expected_id ->
      ()
  | Some _ ->
      raise (Json.DecodeError "JSON-RPC response ID does not match request ID")
  | None ->
      raise (Json.DecodeError "missing JSON-RPC response ID"));
  match (List.assoc_opt "result" fields, List.assoc_opt "error" fields) with
  | Some result, None ->
      if status_code < 200 || status_code >= 300 then
        raise (HttpError (status_code, response_body));
      Lwt.return (send_message_response_of_json result)
  | None, Some error ->
      raise (RpcError (rpc_error_of_json error))
  | Some _, Some _ ->
      raise
        (Json.DecodeError "JSON-RPC response contains both result and error")
  | None, None ->
      raise
        (Json.DecodeError "JSON-RPC response contains neither result nor error")

let task_of_json json =
  let fields =
    match json with
    | `Assoc x ->
        x
    | _ ->
        raise (Json.DecodeError "task is not an object")
  in
  let id =
    match List.assoc_opt "id" fields with
    | Some (`String x) ->
        x
    | Some _ ->
        raise (Json.DecodeError "id is not a string")
    | None ->
        raise (Json.DecodeError "missing id")
  in
  let context_id =
    match List.assoc_opt "contextId" fields with
    | Some (`String x) ->
        x
    | Some _ ->
        raise (Json.DecodeError "contextId is not a string")
    | None ->
        raise (Json.DecodeError "missing contextId")
  in
  let status =
    match List.assoc_opt "status" fields with
    | Some value ->
        Json.task_status_of_json value
    | None ->
        raise (Json.DecodeError "missing status")
  in
  let artifacts =
    match List.assoc_opt "artifacts" fields with
    | Some (`List x) ->
        List.map Json.artifact_of_json x
    | Some _ ->
        raise (Json.DecodeError "artifacts is not an array")
    | None ->
        []
  in
  let history =
    match List.assoc_opt "history" fields with
    | Some (`List x) ->
        List.map Json.message_of_json x
    | Some _ ->
        raise (Json.DecodeError "history is not an array")
    | None ->
        []
  in
  let metadata =
    match List.assoc_opt "metadata" fields with
    | Some (`Assoc value) ->
        Some value
    | Some _ ->
        raise (Json.DecodeError "metadata is not an object")
    | None ->
        None
  in
  { Types.id; context_id; status; artifacts; history; metadata }
