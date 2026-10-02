type send_message_params = {
  message : Types.message;
  configuration : Yojson.Safe.t option;
  metadata : Types.metadata option;
}

type request = {
  jsonrpc : string;
  id : id;
  method_ : method_;
  params : Yojson.Safe.t option;
}

val method_to_string : method_ -> string
val request : ?params:Yojson.Safe.t -> id -> method_ -> request
val send_message_request : id -> send_message_params -> request
val request_to_json : request -> Yojson.Safe.t
val response_to_json : response -> Yojson.Safe.t

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

type id =
  | StringId of string
  | IntId of int

let id_to_json = function
  | StringId value ->
      `String value
  | IntId value ->
      `Int value

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

type error = {
  code : int;
  message : string;
  data : Yojson.Safe.t option;
}

type response =
  | Result of {
      jsonrpc : string;
      id : id;
      result : Yojson.Safe.t;
    }
  | Error of {
      jsonrpc : string;
      id : id option;
      error : error;
    }
