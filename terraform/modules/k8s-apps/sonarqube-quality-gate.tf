resource "sonarqube_qualitygate" "custom" {
  count = var.sonarqube_external_url != null ? 1 : 0

  name       = "Custom-Quality-Gate"
  is_default = true

  condition {
    metric    = "code_smells"
    op        = "GT"
    threshold = "12"
  }

  condition {
    metric    = "coverage"
    op        = "LT"
    threshold = "60"
  }

  depends_on = [null_resource.sonarqube_setup]
}
