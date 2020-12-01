# Create spaces
resource kibana_user_space "us" {
    for_each          = var.user_spaces
    name              = each.key
    description       = each.value.description
    disabled_features = each.value.disabled_features
}

# Create roles
resource kibana_role "role" {
    for_each = var.kibana_roles
    name     = each.key
    dynamic "kibana" {
        for_each = each.value.kibana[*]
        content {
            base   = kibana.value.base
            spaces = kibana.value.spaces
        }
    }
    depends_on = [ kibana_user_space.us ]
}


# Create index patterns
resource kibana_object "object" {
    for_each        = var.kibana_objects
    name            = each.key
    data            = file(each.value.data)
    space           = each.value.space
    deep_reference	= each.value.deep_reference
    dynamic "export_objects" {
        for_each = each.value.export_objects[*]
        content {
            id   = export_objects.value.id
            type = export_objects.value.type
        }
    }
}




