resource "aws_s3_bucket" "redirect" {
  count = var.create_redirect ? 1 : 0
  bucket = var.rf_source_bucket
  force_destroy = true
}

resource "aws_s3_bucket_policy" "redirect" {
  count = var.create_redirect ? 1 : 0
  bucket = aws_s3_bucket.redirect[count.index].bucket
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
        "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
          "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.rf_source_bucket}/*"]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_acl" "redirect" {
  count = var.create_redirect ? 1 : 0
  bucket = aws_s3_bucket.redirect[count.index].bucket
  acl = "public-read"
}

resource "aws_s3_bucket_lifecycle_configuration" "redirect" {
  count = var.create_redirect ? 1 : 0
  bucket = aws_s3_bucket.redirect[count.index].bucket
  rule {
    id = var.rf_source_bucket
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  count = var.create_redirect ? 1 : 0
  bucket = aws_s3_bucket.redirect[count.index].bucket

    dynamic "redirect_all_requests_to" {
    for_each = try([var.create_redirect_content["redirect_all_requests_to"]], [])
    content {
      host_name = try(redirect_all_requests_to.value.host_name, var.app_domain_name)
      protocol  = try(redirect_all_requests_to.value.protocol, "https")
    }
  }

    dynamic "index_document" {
    for_each = try([var.create_redirect_content["index_document"]], [])
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = try([var.create_redirect_content["error_document"]], [])
    content {
      key = error_document.value
    }
  }


  dynamic "routing_rule" {
    for_each = try(flatten([var.create_redirect_content["routing_rules"]]), [])

    content {
      dynamic "condition" {
        for_each = [try([routing_rule.value.condition], [])]
        content {
          http_error_code_returned_equals = try(routing_rule.value.condition["http_error_code_returned_equals"], null)
          key_prefix_equals               = try(routing_rule.value.condition["key_prefix_equals"], null)
        }
      }

      dynamic "redirect" {
        for_each = [try([routing_rule.value.redirect], [])]
        content {
          host_name               = try(routing_rule.value.redirect["host_name"], var.app_domain_name)
          http_redirect_code      = try(routing_rule.value.redirect["http_redirect_code"], null)
          protocol                = try(routing_rule.value.redirect["protocol"], "https")
          replace_key_prefix_with = try(routing_rule.value.redirect["replace_key_prefix_with"], null)
          replace_key_with        = try(routing_rule.value.redirect["replace_key_with"], null)
        }
      }
    }
  }
}

resource "aws_cloudfront_distribution" "s3_distribution_redirect" {
  count = var.create_redirect ? 1 : 0
  origin {
    domain_name = aws_s3_bucket_website_configuration.redirect[0].website_endpoint
    origin_id   = "${var.s3_origin_id}Redir"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment

  logging_config {
    include_cookies = false
    bucket          = "${var.logs_bucket}.s3.amazonaws.com"
    prefix          = var.rf_source_bucket
  }

  aliases = [var.rf_domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.s3_origin_id}Redir"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    # min_ttl                = var.min_ttl
    # default_ttl            = var.default_ttl
    # max_ttl                = var.max_ttl
    # compress               = var.compress
  }

  price_class = var.price_class

  restrictions {
    dynamic "geo_restriction" {
      for_each = var.geo_restriction ? [] : [1]
      content {
        restriction_type = "none"
      }
    }

    dynamic "geo_restriction" {
      for_each = var.geo_restriction ? [1] : []
      content {
        restriction_type = "whitelist"
        locations        = var.restriction_locations
      }
    }

  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    minimum_protocol_version = var.minimum_protocol_version
    ssl_support_method = "sni-only"
  }
  depends_on = [aws_s3_bucket.redirect[0]]
}

resource "aws_route53_record" "web_record_redirect" {
  count = var.create_redirect ? 1 : 0
  zone_id = var.zone_id # Replace with your zone ID
  name    = "${var.rf_domain_name}."                    # Replace with your name/domain/subdomain
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.s3_distribution_redirect[0].domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.s3_distribution_redirect[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution_redirect[0]]
}