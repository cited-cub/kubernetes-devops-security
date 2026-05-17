locals {
  docker_config = jsonencode({
    auths = {
      (var.harbor_url) = {
        auth = base64encode("${var.harbor_username}:${var.harbor_password}")
      }
    }
  })
}

resource "kubernetes_secret" "harbor_credentials" {
  metadata {
    name      = "harbor-credentials"
    namespace = "jenkins"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.docker_config
  }
}
