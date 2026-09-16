open Types

type send_message_request = {
  tenant : string option;
  message : message;
  configuration : send_message_configuration option;
  metadata : metadata option;
}

type send_message_params = {
  message : Types.message;
  configuration : Yojson.Safe.t option;
  metadata : Types.metadata option;
}

type get_task_request = {
  tenant : string option;
  id : string;
  history_length : int option;
}

type list_tasks_request = {
  tenant : string option;
  context_id : string option;
  status : task_state option;
  page_size : int option;
  page_token : string option;
  history_length : int option;
  status_timestamp_after : Ptime.t option;
  include_artifacts : bool option;
}

type cancel_task_request = {
  tenant : string option;
  id : string;
  metadata : metadata option;
}

type subscribe_to_task_request = {
  tenant : string option;
  id : string;
}

type create_task_push_notification_config_request =
  task_push_notification_config

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

type get_extended_agent_card_request = { tenant : string option }
type send_message_response = Types.send_message_response
type list_tasks_response = Types.list_tasks_response

type list_task_push_notification_configs_response =
  Types.list_task_push_notification_configs_response

let send_message_request ?tenant ?configuration ?metadata message =
  { tenant; message; configuration; metadata }

let get_task_request ?tenant ?history_length id = { tenant; id; history_length }

let list_tasks_request ?tenant ?context_id ?status ?page_size ?page_token
    ?history_length ?status_timestamp_after ?include_artifacts () =
  {
    tenant;
    context_id;
    status;
    page_size;
    page_token;
    history_length;
    status_timestamp_after;
    include_artifacts;
  }

let cancel_task_request ?tenant ?metadata id = { tenant; id; metadata }
let subscribe_to_task_request ?tenant id = { tenant; id }

let get_task_push_notification_config_request ?tenant ~task_id id =
  { tenant; task_id; id }

let list_task_push_notification_configs_request ?tenant ~task_id
    ?(page_size = 0) ?(page_token = "") () =
  { tenant; task_id; page_size; page_token }

let delete_task_push_notification_config_request ?tenant ~task_id id =
  { tenant; task_id; id }

let get_extended_agent_card_request ?tenant () = { tenant }
