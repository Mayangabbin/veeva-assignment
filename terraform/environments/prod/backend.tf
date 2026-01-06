terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "envs/prod/terraform.tfstate" 
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
  }
}
