variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "region" {
  description = "Free tier eligible region (us-central1, us-east1, us-west1)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone inside the free tier region"
  type        = string
  default     = "us-central1-a"
}

variable "ssh_user" {
  description = "Your local SSH username"
  type        = string
  default     = "hermes"
}

variable "ssh_public_key" {
  description = "Public SSH key string (e.g. contents of ~/.ssh/id_ed25519.pub)"
  type        = string
}
