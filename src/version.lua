-- versioning --

do
  k._VERSION = {
    major = "@[{os.getenv 'KV_MAJOR' or '2'}]",
    minor = "@[{os.getenv 'KV_MINOR' or '0'}]",
    patch = "@[{os.getenv 'KV_PATCH' or '0'}]",
    build_host = "$[{hostnamectl hostname}]",
    build_user = "@[{os.getenv 'USER' or 'none'}]",
    build_name = "@[{os.getenv 'KNAME' or 'default'}]"
  }
  _G._OSVERSION = string.format("Cynosure %s.%s.%s-%s",
    k._VERSION.major, k._VERSION.minor, k._VERSION.patch, k._VERSION.build_name)
end
