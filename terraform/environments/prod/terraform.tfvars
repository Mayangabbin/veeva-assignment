environment = "prod"
region = "eu-central-1"
azs = "eu-central-1a", "eu-central-1b"
prefix = "veeva"
public_subnets = {
  "eu-central-1a" = "10.0.1.0/24"
  "eu-central-1b" = "10.0.2.0/24"
}
private_app_subnets = {
  "eu-central-1a" = "10.0.10.0/24"
  "eu-central-1b" = "10.0.11.0/24"
}
private_db_subnets = {
  "eu-central-1a" = "10.0.20.0/24"
  "eu-central-1b" = "10.0.21.0/24"
}
namespace  = "veeva-app"
node_instance_type = "m5.large"
db_engine = "postgres"
db_engine_version = "15.3"
db_instance_class = "db.t3.medium"
