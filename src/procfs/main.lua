-- procfs --

do
  k.state.procfs = k.common.ramfs.new("procfs")
  k.state.mount_sources.procfs = k.state.procfs
end
