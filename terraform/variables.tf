variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context to use"
  type        = string
  default     = ""
}

variable "harbor_url" {
  description = "Harbor registry URL (host:port, no protocol)"
  type        = string
}

variable "harbor_username" {
  description = "Harbor registry username"
  type        = string
  sensitive   = true
}

variable "harbor_password" {
  description = "Harbor registry password"
  type        = string
  sensitive   = true
}
