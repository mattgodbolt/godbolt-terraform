variable "bucket" {
  description = "The S3 bucket to store in"
  type        = string
}

variable "deploy_user" {
  description = "Username of the IAM user to deploy"
  type        = string
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

variable "protected_prefixes" {
  default     = []
  description = "Key prefixes (S3 wildcards, e.g. \"archive/*\") the deploy user may write to but never delete from"
  type        = list(string)
}

variable "api_origins" {
  default     = []
  description = "Uncached origins served under a path pattern of the distribution, e.g. a Lambda function URL at /api/foo/*"
  type = list(object({
    path_pattern = string
    domain_name  = string
  }))
}
