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
  (* FIXME - only for debugging *)
  (* message : string; *)
  message2 : string;
  data : Yojson.Safe.t option;
}

let error_to_json (rpc_error : rpc_error) =
  let fields0 =
    [ ("code", `Int rpc_error.code); ("message", `String rpc_error.message2) ]
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

let send_rpc_message url id params =
  let request =
    build_rpc_request
      ~params:(send_message_params_to_json params)
      id SendMessage
  in
  let body =
    request |> request_to_json |> Yojson.Safe.to_string
    |> Cohttp_lwt.Body.of_string
  in
  let headers = Cohttp.Header.init_with "Content-Type" "application/json" in
  Cohttp_lwt_unix.Client.post ~headers ~body (Uri.of_string url)
