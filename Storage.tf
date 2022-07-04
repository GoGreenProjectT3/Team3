
# #Creating S3bucket
resource "random_pet" "petname" {
  length    = 3
  separator = "-"
}



resource "aws_s3_bucket" "gogreen-s3" {
  bucket = "ngs-gn-glacier001-${random_pet.petname.id}-${data.aws_region.current.id}"
}
data "aws_region" "current" {}


output "bucketarn" {
  value = aws_s3_bucket.gogreen-s3.arn
}

resource "aws_s3_bucket_lifecycle_configuration" "gogreen-s3" {
  bucket = aws_s3_bucket.gogreen-s3.id
  rule {
    id = "archive"
    filter {
      prefix = "archive/"
      tag {
        key   = "rule"
        value = "archive"
      }
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 180
    }
    status = "Enabled"
  }

  rule {
    id = "S3glacier"
    filter {
      prefix = "glacier/"
      tag {
        key   = "rule"
        value = "glacier"
      }
    }
    expiration {
      days = 1825
    }
    transition {
      days          = 1
      storage_class = "GLACIER"
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "gogreen-s3" {
  bucket = aws_s3_bucket.gogreen-s3.id
  acl    = "private"
}
# Enable versioning able to see full revision history of our state files

resource "aws_s3_bucket_versioning" "versioning_gogreen-tf-state" {
  bucket = aws_s3_bucket.gogreen-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# provider "aws" {
#   region = "us-west-1"

#   # Make it faster by skipping something

#   skip_get_ec2_platforms      = true
#   skip_metadata_api_check     = true
#   skip_region_validation      = true
#   skip_credentials_validation = true
#   skip_requesting_account_id  = true
# }

# locals {
#   bucket_name = "ngs-gn-glacier001-${random_pet.this.id}"
#   region      = "us-west-1"
# }


# data "aws_caller_identity" "current" {}

# data "aws_canonical_user_id" "current" {}

# data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}

# resource "random_pet" "this" {
#   length = 2
# }

# resource "aws_kms_key" "objects" {
#   description             = "KMS key is used to encrypt bucket objects"
#   deletion_window_in_days = 7
# }

# resource "aws_iam_role" "this" {
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# data "aws_iam_policy_document" "bucket_policy" {
#   statement {
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.this.arn]
#     }

#     actions = [
#       "s3:ListBucket",
#     ]

#     resources = [
#       "arn:aws:s3:::${local.bucket_name}",
#     ]
#   }
# }

# module "log_bucket" {
#   source = "../../"

#   bucket        = "logs-${random_pet.this.id}"
#   acl           = "log-delivery-write"
#   force_destroy = true

#   attach_elb_log_delivery_policy        = true
#   attach_lb_log_delivery_policy         = true
#   attach_deny_insecure_transport_policy = true
#   attach_require_latest_tls_policy      = true
# }

# module "cloudfront_log_bucket" {
#   source = "../../"

#   #bucket = "cloudfront-logs-${random_pet.this.id}"

#   grant = [{
#     type       = "CanonicalUser"
#     permission = "FULL_CONTROL"
#     id         = data.aws_canonical_user_id.current.id
#     }, {
#     type       = "CanonicalUser"
#     permission = "FULL_CONTROL"
#     id         = data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront.id # Ref. https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
#     }
#   ]

#   # owner = {
#   #   id = "457414f555e45c2e6fe1069d1a527a90d6337e1acb012ba99f3833859b23d338"
#   #   force_destroy = true
#   # }


# }

# module "s3_bucket" {
#   source = "../../"

#   bucket = local.bucket_name

#   force_destroy       = true
#   acceleration_status = "Suspended"
#   request_payer       = "BucketOwner"

#   tags = {
#     Owner = "Anton"
#   }

#   # Note: Object Lock configuration can be enabled only on new buckets
#   # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration
#   object_lock_enabled = true
#   object_lock_configuration = {
#     rule = {
#       default_retention = {
#         mode = "GOVERNANCE"
#         days = 1
#       }
#     }
#   }

#   # Bucket policies
#   attach_policy                         = true
#   policy                                = data.aws_iam_policy_document.bucket_policy.json
#   attach_deny_insecure_transport_policy = true
#   attach_require_latest_tls_policy      = true

#   # S3 bucket-level Public Access Block configuration
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   # S3 Bucket Ownership Controls
#   # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
#   control_object_ownership = true
#   object_ownership         = "BucketOwnerPreferred"

#   expected_bucket_owner = data.aws_caller_identity.current.account_id

#   acl = "private" # "acl" conflicts with "grant" and "owner"

#   logging = {
#     target_bucket = module.log_bucket.s3_bucket_id
#     target_prefix = "log/"
#   }

#   versioning = {
#     status     = true
#     mfa_delete = false
#   }

#   website = {
#     # conflicts with "error_document"
#     #        redirect_all_requests_to = {
#     #          host_name = "https://modules.tf"
#     #        }

#     index_document = "index.html"
#     error_document = "error.html"
#     routing_rules = [{
#       condition = {
#         key_prefix_equals = "docs/"
#       },
#       redirect = {
#         replace_key_prefix_with = "documents/"
#       }
#       }, {
#       condition = {
#         http_error_code_returned_equals = 404
#         key_prefix_equals               = "archive/"
#       },
#       redirect = {
#         host_name          = "archive.myhost.com"
#         http_redirect_code = 301
#         protocol           = "https"
#         replace_key_with   = "not_found.html"
#       }
#     }]
#   }

#   server_side_encryption_configuration = {
#     rule = {
#       apply_server_side_encryption_by_default = {
#         kms_master_key_id = aws_kms_key.objects.arn
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }

#   cors_rule = [
#     {
#       allowed_methods = ["PUT", "POST"]
#       allowed_origins = ["https://modules.tf", "https://terraform-aws-modules.modules.tf"]
#       allowed_headers = ["*"]
#       expose_headers  = ["ETag"]
#       max_age_seconds = 3000
#       }, {
#       allowed_methods = ["PUT"]
#       allowed_origins = ["https://example.com"]
#       allowed_headers = ["*"]
#       expose_headers  = ["ETag"]
#       max_age_seconds = 3000
#     }
#   ]

#   lifecycle_rule = [
#     {
#       id      = "log"
#       enabled = true

#       filter = {
#         tags = {
#           some    = "value"
#           another = "value2"
#         }
#       }

#       transition = [
#         {
#           days          = 30
#           storage_class = "ONEZONE_IA"
#           }, {
#           days          = 60
#           storage_class = "GLACIER"
#         }
#       ]

#       #        expiration = {
#       #          days = 90
#       #          expired_object_delete_marker = true
#       #        }

#       #        noncurrent_version_expiration = {
#       #          newer_noncurrent_versions = 5
#       #          days = 30
#       #        }
#     },
#     {
#       id                                     = "log1"
#       enabled                                = true
#       abort_incomplete_multipart_upload_days = 7

#       noncurrent_version_transition = [
#         {
#           days          = 30
#           storage_class = "STANDARD_IA"
#         },
#         {
#           days          = 60
#           storage_class = "ONEZONE_IA"
#         },
#         {
#           days          = 90
#           storage_class = "GLACIER"
#         },
#       ]

#       noncurrent_version_expiration = {
#         days = 300
#       }
#     },
#     {
#       id      = "log2"
#       enabled = true

#       filter = {
#         prefix                   = "log1/"
#         object_size_greater_than = 200000
#         object_size_less_than    = 500000
#         tags = {
#           some    = "value"
#           another = "value2"
#         }
#       }

#       noncurrent_version_transition = [
#         {
#           days          = 30
#           storage_class = "STANDARD_IA"
#         },
#       ]

#       noncurrent_version_expiration = {
#         days = 300
#       }
#     },
#   ]

#   intelligent_tiering = {
#     general = {
#       status = "Enabled"
#       filter = {
#         prefix = "/"
#         tags = {
#           Environment = "dev"
#         }
#       }
#       tiering = {
#         ARCHIVE_ACCESS = {
#           days = 180
#         }
#       }
#     },
#     documents = {
#       status = false
#       filter = {
#         prefix = "documents/"
#       }
#       tiering = {
#         ARCHIVE_ACCESS = {
#           days = 125
#         }
#         DEEP_ARCHIVE_ACCESS = {
#           days = 200
#         }
#       }
#     }
#   }
#   }


# # resource "aws_s3_bucket" "ngs-ggn-bucket001" {
# #   bucket = "ngs-ggn-bucket001"
# #   acl    = "private"
# #   lifecycle_rule {
# #     id      = "my-ggn_quarterly_retention"
# #     prefix  = "folder/"
# #     enabled = true

# #     expiration {
# #       days = 90
# #     }
# #   }
# #   versioning {
# #     enabled = true
# #   }
# # }



# # resource "aws_s3_bucket" "ngs-gn-glacier001" {
# #   bucket = "ngs-ggn-glacier001"
# #   acl    = "private"
# #   lifecycle_rule {
# #     id      = "my-ggn-glacier-fiveyears_retention"
# #     prefix  = "folder/"
# #     enabled = true

# #     expiration {
# #       days = 1825
# #     }

# #     transition {
# #       days          = 1
# #       storage_class = "GLACIER"
# #     }
# #   }
# # }



# # #route53domains registered domain

# # resource "aws_route53domains_registered_domain" "gogreen_aws" {
# #   domain_name = "www.ggn-green.link"

# # }

# # #Create route53_zone

# # resource "aws_route53_zone" "gogreen_aws" {
# #   name = "www.ggn-green.link"


# #   tags = {
# #     Environment = "dev"
# #   }
# # }
# # # Creating EIP

# # resource "aws_eip" "eip_r53" {
# #   vpc = true
# # }


# # resource "aws_route53_record" "www" {
# #   zone_id = aws_route53_zone.gogreen_aws.zone_id
# #   name    = "www.ggn-green.link"
# #   type    = "A"
# #   ttl     = "300"
# #   records = [aws_eip.eip_r53.public_ip]
# # }

# # # # Creating cloudfront_distribution

# # resource "aws_cloudfront_distribution" "s3_distribution" {
# #   origin {
# #     domain_name = aws_s3_bucket.a.bucket_regional_domain_name
# #     origin_id   = aws_s3_bucket.a.id
# #     {

# #     s3_origin_config {
# #       origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
# #     }
# #   }

# #   enabled = true
# #   is_ipv4_enabled     = true
# #   comment             = "Some comment"
# #   default_root_object = "index.html"

# #   logging_config {
# #     include_cookies = false
# #     bucket          = "mylogs.s3.amazonaws.com"
# #     prefix          = "myprefix"
# #   }

# #   #aliases = ["mysite.example.com", "yoursite.example.com"]

# #   default_cache_behavior {
# #     allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
# #     cached_methods   = ["GET", "HEAD"]
# #     target_origin_id = aws_s3_bucket.a.id

# #     forwarded_values {
# #       query_string = false

# #       cookies {
# #         forward = "none"
# #       }
# #     }

# #     viewer_protocol_policy = "allow-all"
# #     min_ttl                = 0
# #     default_ttl            = 3600
# #     max_ttl                = 86400
# #   }



# # # Cache behavior with precedence 1

# # ordered_cache_behavior {
# #   path_pattern     = "/content/*"
# #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
# #   cached_methods   = ["GET", "HEAD"]
# #   target_origin_id = aws_s3_bucket.a.id

# #   forwarded_values {
# #     query_string = false

# #     cookies {
# #       forward = "none"
# #     }
# #   }

# #   min_ttl                = 0
# #   default_ttl            = 3600
# #   max_ttl                = 86400
# #   compress               = true
# #   viewer_protocol_policy = "redirect-to-https"
# # }

# # price_class = "PriceClass_200"

# # restrictions {
# #   geo_restriction {
# #     restriction_type = "whitelist"
# #     locations        = ["US", "CA", "GB", "DE"]
# #   }
# # }

# # tags = {
# #   Environment = "production"
# # }

# # viewer_certificate {
# #   cloudfront_default_certificate = true
# # }
