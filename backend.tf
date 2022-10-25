terraform {
  backend "remote" {
    organization = "cbates255"

    workspaces {
      name = "terraform21_project"
    }
  }
}
