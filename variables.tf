variable "source_bucket" {
  default = ""
}

variable "logs_bucket" {
  default = ""
}

variable "website" {
    default = {
      index_document = "index.html"
      error_document = "index.html"
    }
}

variable "custom_error_index_document" {
  default = "/index.html"
  description = "global error document for reactor router"
}

variable "s3_origin_id" {
  default = ""
}

variable "app_domain_name" {
  default = ""
}

variable "app_additional_domain_names" {
  default = []
  type = list
}

variable "min_ttl" {
  default = 0
}

variable "default_ttl" {
  default = 60
}

variable "max_ttl" {
  default = 300
}

variable "compress" {
  default = false
  type = bool
}

variable "price_class" {
  default = "PriceClass_100"
}

## domyslnie data.terraform_remote_state.domain_cert_us.outputs.certificate_arn
variable "acm_certificate_arn" {
  default = ""
}

## data.terraform_remote_state.domain_cert_us.outputs.zone_id
variable "zone_id" {
  default = ""
}

variable "comment" {
  default = "created by SilkSH with terraform"
}

variable "minimum_protocol_version" {
  default = "TLSv1.2_2018"
}

variable "geo_restriction" {
  type = bool
  default = false
}

variable "restriction_locations" {
  default = ["PL", "US", "GB", "DE", "CA"]
}

variable "create_redirect" {
  default = false
  type = bool
  description = "will we create redirection (for ex. from www to non-www)"
}

variable "create_redirect_content" {
  default = {
    redirect_all_requests_to = {
      # host_name = "example.com" # default to var.app_domain_name
      protocol = "https"
    }
  }
}

variable "rf_source_bucket" {
  default = ""
}

variable "rf_domain_name" {
  default = ""
}

variable "routing_rules" {
  default = "" 
  description = "A json array containing routing rules describing redirect behavior and when redirects are applied"
  type        = string
}

variable "lambda_association" {
  type = list(object({
    event_type = string,
    include_body = bool,
    lambda_arn = string
  }))

  default = null
  
}

variable "function_association" {
  type = list(object({
    event_type = string,
    function_arn = string
  }))

  default = null
  
}

variable "response_headers_policy_id" {
  default = ""
}

variable "cache_policy_id" {
  default = ""
}

variable "request_policy_id" {
  default = ""
}

variable "web_acl_id" {
  default = ""
}

variable "custom_error_response_code" {
  default = 200
}

variable "enabled" {
  default = true
}

variable "secure_s3_origin" {
  default = false
  
}

variable "is_ipv6_enabled" {
  default = true
}

variable "bucket_block_public_acls" {
  description = "Specifies whether Amazon S3 blocks public ACLs for this bucket."
  type        = bool
  default     = false
}

variable "bucket_block_public_policy" {
  description = "Specifies whether Amazon S3 blocks public bucket policies for this bucket."
  type        = bool
  default     = false
}

variable "bucket_ignore_public_acls" {
  description = "Specifies whether Amazon S3 ignores public ACLs for this bucket."
  type        = bool
  default     = false
}

variable "bucket_restrict_public_buckets" {
  description = "Specifies whether Amazon S3 restricts public bucket policies for this bucket."
  type        = bool
  default     = false
}

variable "bucket_noncurrent_version_expiration_days" {
  default = 90
  
}

variable "static_assets_cache_ordered_cache_behaviors" {
  description = "List of ordered cache behaviors for specific path patterns"
  type = list(object({
    path_pattern = string
    ttl          = optional(number)
    min_ttl      = optional(number)
    default_ttl  = optional(number)
    max_ttl      = optional(number)
  }))
  default = []
}

variable "static_assets_cache_custom_headers_config_value" {
  description = "Value for Cache-Control header in static assets cache policy"
  type        = string
  default     = "public, max-age=31536000, immutable"
}