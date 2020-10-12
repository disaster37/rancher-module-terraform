terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    elasticsearch = ">= 7.0.0"
    kibana = ">= 7.0.0"
  }
}