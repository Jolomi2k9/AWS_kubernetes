terraform {
  cloud {
    organization = "tr-kuber"

    workspaces {
      name = "tr-dev"
    }
  }
}