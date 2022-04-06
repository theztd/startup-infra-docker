namespace "default" {
  policy = "write"
  capabilities = ["read-logs", "alloc-exec", "read-fs", "dispatch-job", "alloc-lifecycle"]
}

namespace "system" {
  policy = "deny"
}

agent {
  policy = "read"
}

node {
  policy = "read"
}

quota {
  policy = "read"
}