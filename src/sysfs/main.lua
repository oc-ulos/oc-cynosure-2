-- sysfs --

do
  k.state.sysfs = k.common.ramfs.new("sysfs")
  k.state.mount_sources.sysfs = k.state.sysfs
end
