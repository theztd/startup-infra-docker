namespace "*" {
  policy = "write"

  variables {
    path "*" {
      capabilities = ["write"]
    }
  }
}

agent {
  policy = "write"
}

node {
  policy = "write"
}

quota {
  policy = "write"
}
