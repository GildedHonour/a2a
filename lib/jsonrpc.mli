type method_
type id
type request
type response

val method_to_string : method_ -> string
val send_request : ?params:Yojson.Safe.t -> id -> method_ -> request
val request_to_json : request -> Yojson.Safe.t
val response_to_json : response -> Yojson.Safe.t
