type send_message_request = {
  tenant : string option;
  message : Types.message;
  configuration : Types.send_message_configuration option;
  metadata : Types.metadata option;
}

val build_send_message_request :
  ?tenant:string ->
  ?configuration:Types.send_message_configuration ->
  ?metadata:Types.metadata ->
  Types.message ->
  send_message_request

(* FIXME *)

(*
type get_task_request = {
  tenant : string option;
  id : string;
  history_length : int option;
}

type list_tasks_request = {
  tenant : string option;
  context_id : string option;
  status : Types.task_state option;
  page_size : int option;
  page_token : string option;
  history_length : int option;
  status_timestamp_after : Ptime.t option;
  include_artifacts : bool option;
}

type cancel_task_request = {
  tenant : string option;
  id : string;
  metadata : Types.metadata option;
}

type subscribe_to_task_request = {
  tenant : string option;
  id : string;
}

type create_task_push_notification_config_request =
  Types.task_push_notification_config

type get_task_push_notification_config_request = {
  tenant : string option;
  task_id : string;
  id : string;
}

type list_task_push_notification_configs_request = {
  tenant : string option;
  task_id : string;
  page_size : int;
  page_token : string;
}

type delete_task_push_notification_config_request = {
  tenant : string option;
  task_id : string;
  id : string;
}

type get_extended_agent_card_request = {
  tenant : string option;
}

type send_message_response = Types.send_message_response
type list_tasks_response = Types.list_tasks_response

type list_task_push_notification_configs_response =
  Types.list_task_push_notification_configs_response



val get_task_request :
  ?tenant:string ->
  ?history_length:int ->
  string ->
  get_task_request

val list_tasks_request :
  ?tenant:string ->
  ?context_id:string ->
  ?status:Types.task_state ->
  ?page_size:int ->
  ?page_token:string ->
  ?history_length:int ->
  ?status_timestamp_after:Ptime.t ->
  ?include_artifacts:bool ->
  unit ->
  list_tasks_request

val cancel_task_request :
  ?tenant:string ->
  ?metadata:Types.metadata ->
  string ->
  cancel_task_request

val subscribe_to_task_request :
  ?tenant:string ->
  string ->
  subscribe_to_task_request

val get_task_push_notification_config_request :
  ?tenant:string ->
  task_id:string ->
  string ->
  get_task_push_notification_config_request

val list_task_push_notification_configs_request :
  ?tenant:string ->
  task_id:string ->
  ?page_size:int ->
  ?page_token:string ->
  unit ->
  list_task_push_notification_configs_request

val delete_task_push_notification_config_request :
  ?tenant:string ->
  task_id:string ->
  string ->
  delete_task_push_notification_config_request

val get_extended_agent_card_request :
  ?tenant:string ->
  unit ->
  get_extended_agent_card_request

*)
