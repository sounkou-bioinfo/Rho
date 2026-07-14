RhoAwaitable <- s7contract::new_interface("RhoAwaitable", generics = list(rho_await = rho_await))
RhoStreamLike <- s7contract::new_interface(
  "RhoStreamLike",
  generics = list(rho_stream_next = rho_stream_next)
)
