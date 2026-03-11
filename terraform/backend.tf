terraform {
  backend "s3" {
    bucket      = "adn-ai-platform-terraform-state"
    key         = "vpc/terraform.tfstate"
    region      = "ap-southeast-1"
    encrypt     = true
    use_lockfile = true
  }
}
