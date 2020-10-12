# Create user space
resource "kibana_user_space" "user_space" {
    for_each = var.spaces
    name              = each.key
    description       = each.value.description
    disabled_features = each.value.disabled_features
}

# Create write role
resource "kibana_role" "write" {
    for_each = var.spaces
    name     = "space_${replace(each.key, "/[ \\-]/", "_")}_write"
    kibana {
        base    = ["all"]
        spaces  = [kibana_user_space.user_space[each.key].name]
    }
}

# Create read role
resource "kibana_role" "read" {
  for_each  = var.spaces
  name      = "space_${replace(each.key, "/[ \\-]/", "_")}_read"
  kibana {
    base    = ["read"]
    spaces  = [kibana_user_space.user_space[each.key].name]
  }
}

# Copy object if needed
resource kibana_copy_object "copy" {
    for_each      = var.spaces
    name          = "copy_object_${each.key}"
    source_space  = each.value.source_space
    target_spaces = [kibana_user_space.user_space[each.key].name]

    dynamic "object" {
        for_each = each.value.copy_objects[*]
        content {
            id      = object.value["id"]
            type    = object.value["type"]
        }
    }

    force_update = true
}