open Types

exception DecodeError of string

let field name json =
  match Yojson.Safe.Util.member name json with
  | `Null ->
      None
  | value ->
      Some value

let required_field name json =
  match field name json with
  | Some value ->
      value
  | None ->
      raise (DecodeError ("missing field: " ^ name))

let string_field name json =
  match required_field name json with
  | `String value ->
      value
  | _ ->
      raise (DecodeError ("field is not a string: " ^ name))

let optional_string_field name json =
  match field name json with
  | None ->
      None
  | Some (`String value) ->
      Some value
  | Some _ ->
      raise (DecodeError ("field is not a string: " ^ name))

let metadata_to_json metadata = `Assoc metadata

let metadata_of_json = function
  | `Assoc fields ->
      fields
  | _ ->
      raise (DecodeError "metadata is not an object")

let part_to_json (part : Types.part) =
  let fields =
    match part.content with
    | Text text ->
        [ ("text", `String text) ]
    | Raw bytes ->
        [ ("raw", `String (Base64.encode_string (Bytes.to_string bytes))) ]
    | Url url ->
        [ ("url", `String url) ]
    | Data data ->
        [ ("data", data) ]
  in
  let fields =
    match part.metadata with
    | Some metadata ->
        ("metadata", metadata_to_json metadata) :: fields
    | None ->
        fields
  in
  let fields =
    match part.filename with
    | Some filename ->
        ("filename", `String filename) :: fields
    | None ->
        fields
  in
  let fields =
    match part.media_type with
    | Some media_type ->
        ("mediaType", `String media_type) :: fields
    | None ->
        fields
  in
  `Assoc (List.rev fields)

let part_of_json json =
  let content : Types.part_content =
    match
      (field "text" json, field "raw" json, field "url" json, field "data" json)
    with
    | Some (`String text), None, None, None ->
        Text text
    | None, Some (`String raw), None, None -> (
        match Base64.decode raw with
        | Ok decoded ->
            Raw (Bytes.of_string decoded)
        | Error (`Msg message) ->
            raise (DecodeError ("invalid base64: " ^ message)))
    | None, None, Some (`String url), None ->
        Url url
    | None, None, None, Some data ->
        Data data
    | _ ->
        raise (DecodeError "Part must contain exactly one content field")
  in
  let metadata =
    match field "metadata" json with
    | None ->
        None
    | Some value ->
        Some (metadata_of_json value)
  in
  {
    Types.content;
    metadata;
    filename = optional_string_field "filename" json;
    media_type = optional_string_field "mediaType" json;
  }

let optional_metadata_field name json =
  match field name json with
  | None ->
      None
  | Some value ->
      Some (metadata_of_json value)

let string_list_to_json values =
  `List (List.map (fun value -> `String value) values)

let string_list_of_json = function
  | `List values ->
      List.map
        (function
          | `String value ->
              value
          | _ ->
              raise (DecodeError "expected string in string list"))
        values
  | _ ->
      raise (DecodeError "expected string list")

let task_state_to_json = function
  | Unspecified ->
      `String "TASK_STATE_UNSPECIFIED"
  | Submitted ->
      `String "TASK_STATE_SUBMITTED"
  | Working ->
      `String "TASK_STATE_WORKING"
  | Completed ->
      `String "TASK_STATE_COMPLETED"
  | Failed ->
      `String "TASK_STATE_FAILED"
  | Canceled ->
      `String "TASK_STATE_CANCELED"
  | InputRequired ->
      `String "TASK_STATE_INPUT_REQUIRED"
  | Rejected ->
      `String "TASK_STATE_REJECTED"
  | AuthRequired ->
      `String "TASK_STATE_AUTH_REQUIRED"

let task_state_of_json = function
  | `String "TASK_STATE_UNSPECIFIED" ->
      Unspecified
  | `String "TASK_STATE_SUBMITTED" ->
      Submitted
  | `String "TASK_STATE_WORKING" ->
      Working
  | `String "TASK_STATE_COMPLETED" ->
      Completed
  | `String "TASK_STATE_FAILED" ->
      Failed
  | `String "TASK_STATE_CANCELED" ->
      Canceled
  | `String "TASK_STATE_INPUT_REQUIRED" ->
      InputRequired
  | `String "TASK_STATE_REJECTED" ->
      Rejected
  | `String "TASK_STATE_AUTH_REQUIRED" ->
      AuthRequired
  | _ ->
      raise (DecodeError "invalid task state")

let task_push_notification_config_to_json
    (config : Types.task_push_notification_config) =
  let fields0 = [ ("url", `String config.url) ] in
  let fields1 =
    match config.tenant with
    | Some value ->
        ("tenant", `String value) :: fields0
    | None ->
        fields0
  in
  let fields2 =
    match config.id with
    | Some value ->
        ("id", `String value) :: fields1
    | None ->
        fields1
  in
  let fields3 =
    match config.task_id with
    | Some value ->
        ("taskId", `String value) :: fields2
    | None ->
        fields2
  in
  let fields4 =
    match config.token with
    | Some value ->
        ("token", `String value) :: fields3
    | None ->
        fields3
  in
  let fields5 =
    match config.authentication with
    | Some value ->
        ( "authentication",
          `Assoc
            (match value.credentials with
            | Some credentials ->
                [
                  ("scheme", `String value.scheme);
                  ("credentials", `String credentials);
                ]
            | None ->
                [ ("scheme", `String value.scheme) ]) )
        :: fields4
    | None ->
        fields4
  in
  `Assoc (List.rev fields5)

let message_to_json (message : Types.message) =
  let fields =
    [
      ("messageId", `String message.message_id);
      ( "role",
        `String
          (match message.role with
          | Unspecified ->
              "ROLE_UNSPECIFIED"
          | User ->
              "ROLE_USER"
          | Agent ->
              "ROLE_AGENT") );
      ("parts", `List (List.map part_to_json message.parts));
    ]
  in
  let fields =
    match message.context_id with
    | Some value ->
        ("contextId", `String value) :: fields
    | None ->
        fields
  in
  let fields =
    match message.task_id with
    | Some value ->
        ("taskId", `String value) :: fields
    | None ->
        fields
  in
  let fields =
    match message.metadata with
    | Some value ->
        ("metadata", metadata_to_json value) :: fields
    | None ->
        fields
  in
  let fields =
    match message.extensions with
    | [] ->
        fields
    | values ->
        ("extensions", `List (List.map (fun value -> `String value) values))
        :: fields
  in
  let fields =
    match message.reference_task_ids with
    | [] ->
        fields
    | values ->
        ( "referenceTaskIds",
          `List (List.map (fun value -> `String value) values) )
        :: fields
  in
  `Assoc (List.rev fields)

let send_message_configuration_to_json
    (configuration : Types.send_message_configuration) =
  let fields0 =
    [
      ( "acceptedOutputModes",
        `List
          (List.map
             (fun value -> `String value)
             configuration.accepted_output_modes) );
      ("returnImmediately", `Bool configuration.return_immediately);
    ]
  in
  let fields1 =
    match configuration.task_push_notification_config with
    | Some value ->
        ( "taskPushNotificationConfig",
          task_push_notification_config_to_json value )
        :: fields0
    | None ->
        fields0
  in
  let fields2 =
    match configuration.history_length with
    | Some value ->
        ("historyLength", `Int value) :: fields1
    | None ->
        fields1
  in
  `Assoc (List.rev fields2)

let message_of_json json =
  let fields =
    match json with
    | `Assoc fields ->
        fields
    | _ ->
        raise (DecodeError "message is not an object")
  in
  let message_id =
    match List.assoc_opt "messageId" fields with
    | Some (`String value) ->
        value
    | Some _ ->
        raise (DecodeError "messageId is not a string")
    | None ->
        raise (DecodeError "missing messageId")
  in
  let context_id =
    match List.assoc_opt "contextId" fields with
    | Some (`String value) ->
        Some value
    | Some _ ->
        raise (DecodeError "contextId is not a string")
    | None ->
        None
  in
  let task_id =
    match List.assoc_opt "taskId" fields with
    | Some (`String value) ->
        Some value
    | Some _ ->
        raise (DecodeError "taskId is not a string")
    | None ->
        None
  in
  let role : Types.role =
    match List.assoc_opt "role" fields with
    | Some (`String "ROLE_UNSPECIFIED") ->
        Types.Unspecified
    | Some (`String "ROLE_USER") ->
        Types.User
    | Some (`String "ROLE_AGENT") ->
        Types.Agent
    | Some _ ->
        raise (DecodeError "invalid message role")
    | None ->
        raise (DecodeError "missing role")
  in
  let parts =
    match List.assoc_opt "parts" fields with
    | Some (`List values) ->
        List.map part_of_json values
    | Some _ ->
        raise (DecodeError "parts is not an array")
    | None ->
        raise (DecodeError "missing parts")
  in
  let metadata =
    match List.assoc_opt "metadata" fields with
    | Some (`Assoc value) ->
        Some value
    | Some _ ->
        raise (DecodeError "metadata is not an object")
    | None ->
        None
  in
  let extensions =
    match List.assoc_opt "extensions" fields with
    | Some (`List values) ->
        List.map
          (function
            | `String value ->
                value
            | _ ->
                raise (DecodeError "extension is not a string"))
          values
    | Some _ ->
        raise (DecodeError "extensions is not an array")
    | None ->
        []
  in
  let reference_task_ids =
    match List.assoc_opt "referenceTaskIds" fields with
    | Some (`List values) ->
        List.map
          (function
            | `String value ->
                value
            | _ ->
                raise
                  (DecodeError "referenceTaskIds contains a non-string value"))
          values
    | Some _ ->
        raise (DecodeError "referenceTaskIds is not an array")
    | None ->
        []
  in
  {
    Types.message_id;
    context_id;
    task_id;
    role;
    parts;
    metadata;
    extensions;
    reference_task_ids;
  }

let task_status_of_json json =
  let fields =
    match json with
    | `Assoc fields ->
        fields
    | _ ->
        raise (DecodeError "task status is not an object")
  in
  let state =
    match List.assoc_opt "state" fields with
    | Some (`String "TASK_STATE_UNSPECIFIED") ->
        Types.Unspecified
    | Some (`String "TASK_STATE_SUBMITTED") ->
        Types.Submitted
    | Some (`String "TASK_STATE_WORKING") ->
        Types.Working
    | Some (`String "TASK_STATE_COMPLETED") ->
        Types.Completed
    | Some (`String "TASK_STATE_FAILED") ->
        Types.Failed
    | Some (`String "TASK_STATE_CANCELED") ->
        Types.Canceled
    | Some (`String "TASK_STATE_INPUT_REQUIRED") ->
        Types.InputRequired
    | Some (`String "TASK_STATE_REJECTED") ->
        Types.Rejected
    | Some (`String "TASK_STATE_AUTH_REQUIRED") ->
        Types.AuthRequired
    | Some _ ->
        raise (DecodeError "invalid task state")
    | None ->
        raise (DecodeError "missing task state")
  in
  let message =
    match List.assoc_opt "message" fields with
    | Some value ->
        Some (message_of_json value)
    | None ->
        None
  in
  let timestamp =
    match List.assoc_opt "timestamp" fields with
    | Some (`String value) -> (
        match Ptime.of_rfc3339 value with
        | Ok (timestamp, _, _) ->
            Some timestamp
        | Error _ ->
            raise (DecodeError "invalid task status timestamp"))
    | Some _ ->
        raise (DecodeError "timestamp is not a string")
    | None ->
        None
  in
  { Types.state; message; timestamp }

let artifact_of_json json =
  let fields =
    match json with
    | `Assoc fields ->
        fields
    | _ ->
        raise (DecodeError "artifact is not an object")
  in
  let parts =
    match List.assoc_opt "parts" fields with
    | Some (`List values) ->
        List.map part_of_json values
    | Some _ ->
        raise (DecodeError "artifact parts is not an array")
    | None ->
        raise (DecodeError "missing artifact parts")
  in
  let metadata =
    match List.assoc_opt "metadata" fields with
    | Some (`Assoc value) ->
        Some value
    | Some _ ->
        raise (DecodeError "artifact metadata is not an object")
    | None ->
        None
  in
  let extensions =
    match List.assoc_opt "extensions" fields with
    | Some (`List values) ->
        List.map
          (function
            | `String value ->
                value
            | _ ->
                raise (DecodeError "artifact extension is not a string"))
          values
    | Some _ ->
        raise (DecodeError "artifact extensions is not an array")
    | None ->
        []
  in
  {
    Types.artifact_id =
      (match List.assoc_opt "artifactId" fields with
      | Some (`String value) ->
          value
      | Some _ ->
          raise (DecodeError "artifactId is not a string")
      | None ->
          raise (DecodeError "missing artifactId"));
    name =
      (match List.assoc_opt "name" fields with
      | Some (`String value) ->
          Some value
      | Some _ ->
          raise (DecodeError "artifact name is not a string")
      | None ->
          None);
    description =
      (match List.assoc_opt "description" fields with
      | Some (`String value) ->
          Some value
      | Some _ ->
          raise (DecodeError "artifact description is not a string")
      | None ->
          None);
    parts;
    metadata;
    extensions;
  }

let task_of_json json =
  let fields =
    match json with
    | `Assoc fields ->
        fields
    | _ ->
        raise (DecodeError "task is not an object")
  in
  let id =
    match List.assoc_opt "id" fields with
    | Some (`String value) ->
        value
    | Some _ ->
        raise (DecodeError "id is not a string")
    | None ->
        raise (DecodeError "missing id")
  in
  let context_id =
    match List.assoc_opt "contextId" fields with
    | Some (`String value) ->
        value
    | Some _ ->
        raise (DecodeError "contextId is not a string")
    | None ->
        raise (DecodeError "missing contextId")
  in
  let status =
    match List.assoc_opt "status" fields with
    | Some value ->
        task_status_of_json value
    | None ->
        raise (DecodeError "missing status")
  in
  let artifacts =
    match List.assoc_opt "artifacts" fields with
    | Some (`List values) ->
        List.map artifact_of_json values
    | Some _ ->
        raise (DecodeError "artifacts is not an array")
    | None ->
        []
  in
  let history =
    match List.assoc_opt "history" fields with
    | Some (`List values) ->
        List.map message_of_json values
    | Some _ ->
        raise (DecodeError "history is not an array")
    | None ->
        []
  in
  let metadata =
    match List.assoc_opt "metadata" fields with
    | Some (`Assoc value) ->
        Some value
    | Some _ ->
        raise (DecodeError "metadata is not an object")
    | None ->
        None
  in
  { Types.id; context_id; status; artifacts; history; metadata }
