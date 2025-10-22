# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "saudat-terraform-state-lock"
    key            = "vpc-s3-endpoint/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}

