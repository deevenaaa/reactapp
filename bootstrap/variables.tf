variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}
variable "tenant_id" {
  description = "Microsoft Entra tenant ID"
  type        = string
}
variable "github_repository" {
  description = "GitHub repository in OWNER/REPOSITORY format"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Enter your repository as OWNER/REPOSITORY."
  }
}