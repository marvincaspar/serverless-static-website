provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "${var.region}"
}

# Only for certificates, because CloudFront supports a default certificate or a custom certificate
# and the custom cerfiticates only available from us-east-1 (n. Virginia)
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "us-east-1"
    alias      = "us-east"
}

#
# S3 Bucket - Bucket to upload the static html website
#
resource "aws_s3_bucket" "storage" {
  bucket = "www.${var.domain}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::www.${var.domain}/*"
        }
    ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags {
    Name        = "${var.domain}"
    Environment = "Prod"
  }
}


#
# Certificate Manager - Request wildcard SSL certificate
#
resource "aws_acm_certificate" "cert" {
  provider                  = "aws.us-east"
  domain_name               = "${var.domain}"
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "EMAIL"

  tags {
    Name        = "${var.domain}"
    Environment = "Prod"
  }
}

resource "aws_acm_certificate_validation" "cert" {
  provider        = "aws.us-east"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}

#
# CloudFront - Setup CDN and use HTTPS
#
resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = ["aws_s3_bucket.storage"]

  # Origin Settings
  origin {
    domain_name = "${aws_s3_bucket.storage.bucket_domain_name}"
    origin_id   = "${aws_s3_bucket.storage.id}"

    # s3_origin_config {
    #   origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
    # }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["${var.domain}", "www.${var.domain}"]

  default_cache_behavior {

    # allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.storage.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  
  tags {
    Name        = "${var.domain}"
    Environment = "Prod"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    # Only available for region us-east-1 (N. Verginia)
    # acm_certificate_arn       = "${aws_acm_certificate.cert.arn}"
    # ssl_support_method        = "sni-only"
    # minimum_protocol_version  = "TLSv1.1_2016"
  }
}

#
# Route53 - 
#
resource "aws_route53_zone" "site_zone" {
  name = "${var.domain}"
  
  tags {
    Name        = "${var.domain}"
    Environment = "Prod"
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "${var.domain}"
  type    = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6-root" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "${var.domain}"
  type    = "AAAA"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6-www" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "www.${var.domain}"
  type    = "AAAA"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}