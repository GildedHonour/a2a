type method_
type id
type request
type response

val method_to_string : method_ -> string
val build_rpc_request : ?params:Yojson.Safe.t -> id -> method_ -> request
val request_to_json : request -> Yojson.Safe.t
val response_to_json : response -> Yojson.Safe.t
val send_message_params_to_json :
  Request.send_message_request -> Yojson.Safe.t
