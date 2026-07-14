AgentEventListener <- s7contract::new_interface(
  "AgentEventListener",
  generics = list(
    rho_handle_agent_event = s7contract::interface_requirement(
      rho_handle_agent_event,
      args = list(event = RhoAgentEvent),
      returns = rho.async::RhoTask
    )
  )
)

AgentPolicy <- s7contract::new_interface(
  "AgentPolicy",
  generics = list(
    rho_transform_agent_context = rho_transform_agent_context,
    rho_before_tool_call = rho_before_tool_call,
    rho_after_tool_call = rho_after_tool_call,
    rho_prepare_next_turn = rho_prepare_next_turn
  )
)
