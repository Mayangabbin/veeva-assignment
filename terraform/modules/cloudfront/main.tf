# Get frontend ALB
data "aws_lb" "frontend_alb" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned"]
  }

  filter {
    name   = "tag:kubernetes.io/ingress-name"
    values = [var.ingress_name]
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "frontend_cf" {
  origin {
    domain_name = data.aws_lb.frontend_alb.dns_name
    origin_id   = "frontend-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "frontend-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = var.cf_waf_arn
  
  tags = var.tags
}
