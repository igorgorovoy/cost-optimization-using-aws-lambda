provider "aws" {
  region = "eu-west-1"
  alias  = "Blue"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "Green"
}
