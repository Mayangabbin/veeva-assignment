# WAF ACL inforces common rules
resource "aws_wafv2_web_acl" "cf" {
  name  = "${var.prefix}-${var.environment}-cf-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "CommonRules"
    priority = 1

    override_action { none {} }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common"
      sampled_requests_enabled   = true
    }
  }
}
