open Types

exception Decode_error of string

let error message = raise (Decode_error message)

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
      error ("missing field: " ^ name)

let string_field name json =
  match required_field name json with
  | `String value ->
      value
  | _ ->
      error ("field is not a string: " ^ name)

let optional_string_field name json =
  match field name json with
  | None ->
      None
  | Some (`String value) ->
      Some value
  | Some _ ->
      error ("field is not a string: " ^ name)

let metadata_to_json metadata = `Assoc metadata

let metadata_of_json = function
  | `Assoc fields ->
      fields
  | _ ->
      error "metadata is not an object"

let part_to_json part =
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
  let content =
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
            error ("invalid base64: " ^ message))
    | None, None, Some (`String url), None ->
        Url url
    | None, None, None, Some data ->
        Data data
    | _ ->
        error "Part must contain exactly one content field"
  in
  let metadata =
    match field "metadata" json with
    | None ->
        None
    | Some value ->
        Some (metadata_of_json value)
  in
  {
    content;
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
              error "expected string in string list")
        values
  | _ ->
      error "expected string list"

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
      raise (Error "invalid task state")
