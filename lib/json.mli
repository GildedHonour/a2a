val part_to_json : Types.part -> Yojson.Safe.t
val part_of_json : Yojson.Safe.t -> Types.part
val message_to_json : Types.message -> Yojson.Safe.t

val send_message_configuration_to_json :
  Types.send_message_configuration -> Yojson.Safe.t

val task_push_notification_config_to_json :
  Types.task_push_notification_config -> Yojson.Safe.t
