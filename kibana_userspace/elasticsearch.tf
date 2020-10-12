# Create role mapping for write
resource elasticsearch_role_mapping "write" {
    for_each = var.spaces
    name    = "space_${replace(each.key, "/[ \\-]/", "_")}_write"
    enabled = "true"
    roles   = [kibana_role.write[each.key].name]
    rules   = "{\"any\":[${join(",", formatlist("{\"field\":{\"groups\":\"%s\"}}", each.value.groups_write))}]}"
}

# Create role mapping for read if needed
resource elasticsearch_role_mapping "read" {
    for_each = var.spaces
    name    = "space_${replace(each.key, "/[ \\-]/", "_")}_read"
    enabled = "true"
    roles   = [kibana_role.read[each.key].name]
    rules   = "{\"any\":[${join(",", formatlist("{\"field\":{\"groups\":\"%s\"}}", concat(each.value.groups_write, each.value.groups_read)))}]}"
}