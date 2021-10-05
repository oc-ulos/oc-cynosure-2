-- devfs --

do
  k.state.devfs = k.common.ramfs.new("devfs")
  k.state.mount_sources.devfs = k.state.devfs
end
