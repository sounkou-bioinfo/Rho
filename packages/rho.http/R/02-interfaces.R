HttpClient <- s7contract::new_interface(
  "HttpClient",
  generics = list(
    rho_http_open_execution = s7contract::interface_requirement(
      rho_http_open_execution,
      returns = RhoHttpOpenExecution
    ),
    rho_http_send = s7contract::interface_requirement(
      rho_http_send,
      args = list(request = RhoHttpRequest),
      returns = rho.async::RhoTask
    ),
    rho_http_open_stream = s7contract::interface_requirement(
      rho_http_open_stream,
      args = list(request = RhoHttpRequest),
      returns = rho.async::RhoTask
    ),
    rho_http_client_close = rho_http_client_close
  )
)
