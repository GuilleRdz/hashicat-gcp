terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "GuilleRdz-dev"
    workspaces {
      name = "hashicat-gcp"
    }
  }
}
