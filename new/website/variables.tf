variable "bucket" {
    description = "The S3 bucket to store in"
    type = string
}

variable "deploy_user" {
    description = "Username of the IAM user to deploy"
    type = string
}

variable "tags" {
  default     = {}
  description = "Resource tags"
  type        = map(string)
}

variable "aliases" {
  default     = []
  description = "Domain aliases"
  type        = list(string)
}

variable "certificate" {
  description = "ARN of certificate to use"
  type        = string
}
