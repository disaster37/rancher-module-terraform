terraform {
  required_version = ">= 0.12.0"

}

locals {  
    copyObjects = {
      for name, space in var.spaces:  name => space
      if space.copy_objects != null
    }
}