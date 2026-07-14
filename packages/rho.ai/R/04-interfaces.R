Provider <- s7contract::new_interface(
  "Provider",
  generics = list(
    rho_stream = s7contract::interface_requirement(
      rho_stream,
      args = list(model = Model, context = Context),
      returns = rho.async::RhoStream
    )
  )
)
Tool <- s7contract::new_interface(
  "Tool",
  generics = list(
    rho_validate_tool_args = s7contract::interface_requirement(
      rho_validate_tool_args,
      args = list(args = S7::class_list)
    ),
    rho_execute_tool = s7contract::interface_requirement(
      rho_execute_tool,
      args = list(call = ToolCall),
      returns = rho.async::RhoTask
    ),
    rho_tool_overlap = s7contract::interface_requirement(
      rho_tool_overlap,
      args = list(call = ToolCall),
      returns = ToolOverlap
    )
  )
)
ProviderEventDecoder <- s7contract::new_interface(
  "ProviderEventDecoder",
  generics = list(rho_decode_provider_event = rho_decode_provider_event)
)
ProviderWireEvent <- s7contract::new_interface(
  "ProviderWireEvent",
  generics = list(rho_reduce_provider_event = rho_reduce_provider_event)
)
ResponseItemProtocol <- s7contract::new_interface(
  "ResponseItemProtocol",
  generics = list(
    rho_start_response_item = rho_start_response_item,
    rho_finish_response_item = rho_finish_response_item
  )
)
CredentialStore <- s7contract::new_interface(
  "CredentialStore",
  generics = list(
    rho_credential_read = rho_credential_read,
    rho_credential_modify = rho_credential_modify,
    rho_credential_delete = rho_credential_delete
  )
)
OAuthAuth <- s7contract::new_interface(
  "OAuthAuth",
  generics = list(
    rho_auth_login = rho_auth_login,
    rho_auth_refresh = rho_auth_refresh,
    rho_auth_to_request = rho_auth_to_request
  )
)
LoginIO <- s7contract::new_interface(
  "LoginIO",
  generics = list(
    rho_auth_prompt = rho_auth_prompt,
    rho_auth_notify = rho_auth_notify
  )
)
ProviderCapabilityResolver <- s7contract::new_interface(
  "ProviderCapabilityResolver",
  generics = list(
    rho_provider_support = s7contract::interface_requirement(
      rho_provider_support,
      args = list(model = Model, operation = RhoProviderOperation),
      returns = RhoProviderSupport
    )
  )
)
ProviderRequestTranslator <- s7contract::new_interface(
  "ProviderRequestTranslator",
  generics = list(
    rho_plan_tools = s7contract::interface_requirement(
      rho_plan_tools,
      args = list(model = Model, context = Context),
      returns = RhoToolPlacement
    ),
    rho_build_provider_request = s7contract::interface_requirement(
      rho_build_provider_request,
      args = list(model = Model, context = Context)
    )
  )
)
ProviderInputCompactor <- s7contract::new_interface(
  "ProviderInputCompactor",
  generics = list(
    rho_compact_provider_input = s7contract::interface_requirement(
      rho_compact_provider_input,
      args = list(model = Model, context = Context),
      returns = rho.async::RhoTask
    )
  )
)
