namespace "default" {
  policy = "write"
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