#
provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# Separate AWS provider for ACM in us-east-1
provider "aws" {
  alias   = "acm_us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}