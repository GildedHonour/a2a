type json = Yojson.Safe.t
type metadata = (string * json) list

type part_content =
  | Text of string
  | Raw of bytes
  | Url of string
  | Data of json

type part = {
  content : part_content;
  metadata : metadata option;
  filename : string option;
  media_type : string option;
}

type role =
  | User
  | Agent

type message = {
  message_id : string;
  context_id : string option;
  task_id : string option;
  role : role;
  parts : part list;
  metadata : metadata option;
  extensions : string list;
  reference_task_ids : string list;
}

type artifact = {
  artifact_id : string;
  name : string option;
  description : string option;
  parts : part list;
  metadata : metadata option;
  extensions : string list;
}

type task_state =
  | Unspecified
  | Submitted
  | Working
  | Completed
  | Failed
  | Canceled
  | InputRequired
  | Rejected
  | AuthRequired

type task_status = {
  state : task_state;
  message : message option;
  timestamp : Ptime.t option;
}

type task = {
  id : string;
  context_id : string;
  status : task_status;
  artifacts : artifact list;
  history : message list;
  metadata : metadata option;
}

type task_status_update_event = {
  task_id : string;
  context_id : string;
  status : task_status;
  metadata : metadata option;
}

type task_artifact_update_event = {
  task_id : string;
  context_id : string;
  artifact : artifact;
  append : bool;
  last_chunk : bool;
  metadata : metadata option;
}

type agent_interface = {
  url : string;
  protocol_binding : string;
  tenant : string option;
  protocol_version : string;
}

type agent_provider = {
  url : string;
  organization : string;
}

type agent_extension = {
  uri : string;
  description : string;
  required : bool;
  params : metadata option;
}

type agent_capabilities = {
  streaming : bool option;
  push_notifications : bool option;
  extensions : agent_extension list;
  extended_agent_card : bool option;
}

type agent_skill = {
  id : string;
  name : string;
  description : string;
  tags : string list;
  examples : string list;
  input_modes : string list;
  output_modes : string list;
  security_requirements : security_requirement list;
}

type agent_card_signature = {
  protected_ : string;
  signature : string;
  header : metadata option;
}

type agent_card = {
  name : string;
  description : string;
  supported_interfaces : agent_interface list;
  provider : agent_provider option;
  version : string;
  documentation_url : string option;
  capabilities : agent_capabilities;
  security_schemes : (string * security_scheme) list;
  security_requirements : security_requirement list;
  default_input_modes : string list;
  default_output_modes : string list;
  skills : agent_skill list;
  signatures : agent_card_signature list;
  icon_url : string option;
}

type string_list = string list
type security_requirement = { schemes : (string * string_list) list }

type api_key_security_scheme = {
  description : string option;
  location : string;
  name : string;
}

type http_auth_security_scheme = {
  description : string option;
  scheme : string;
  bearer_format : string option;
}

type authorization_code_oauth_flow = {
  authorization_url : string;
  token_url : string;
  refresh_url : string option;
  scopes : (string * string) list;
  pkce_required : bool;
}

type client_credentials_oauth_flow = {
  token_url : string;
  refresh_url : string option;
  scopes : (string * string) list;
}

type implicit_oauth_flow = {
  authorization_url : string;
  refresh_url : string option;
  scopes : (string * string) list;
}

type password_oauth_flow = {
  token_url : string;
  refresh_url : string option;
  scopes : (string * string) list;
}

type device_code_oauth_flow = {
  device_authorization_url : string;
  token_url : string;
  refresh_url : string option;
  scopes : (string * string) list;
}

type oauth_flow =
  | Authorization_code of authorization_code_oauth_flow
  | Client_credentials of client_credentials_oauth_flow
  | Implicit of implicit_oauth_flow
  | Password of password_oauth_flow
  | Device_code of device_code_oauth_flow

type oauth_flows = { flow : oauth_flow }

type oauth2_security_scheme = {
  description : string option;
  flows : oauth_flows;
  oauth2_metadata_url : string option;
}

type open_id_connect_security_scheme = {
  description : string option;
  open_id_connect_url : string;
}

type mutual_tls_security_scheme = { description : string option }

type security_scheme =
  | Api_key of api_key_security_scheme
  | Http_auth of http_auth_security_scheme
  | Oauth2 of oauth2_security_scheme
  | Open_id_connect of open_id_connect_security_scheme
  | Mutual_tls of mutual_tls_security_scheme
