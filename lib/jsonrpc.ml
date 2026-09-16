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

let send_request ?params id method_ = { jsonrpc = "2.0"; id; method_; params }

type rpc_error = {
  code : int;
  message : string;
  data : Yojson.Safe.t option;
}

let error_to_json (e : rpc_error) =
  let fields = [ ("code", `Int e.code); ("message", `String e.message) ] in
  let fields =
    match e.data with
    | Some data ->
        ("data", data) :: fields
    | None ->
        fields
  in
  `Assoc (List.rev fields)

(* TODO

let send_message_params_to_json params =
    let fields = [ ("message", Json.message_to_json params.message) ] in
    let fields =
    match params.configuration with
    | Some value ->
        ("configuration", value) :: fields
    | None ->
        fields
    in
    let fields =
    match params.metadata with
    | Some value ->
        ("metadata", Json.metadata_to_json value) :: fields
    | None ->
        fields
    in
    `Assoc (List.rev fields)

*)

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

let request_to_json request =
  let fields =
    [
      ("jsonrpc", `String request.jsonrpc);
      ("id", id_to_json request.id);
      ("method", `String (method_to_string request.method_));
    ]
  in
  let fields =
    match request.params with
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
