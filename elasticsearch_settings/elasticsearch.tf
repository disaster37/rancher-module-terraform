######## 
# Create roles
########
resource elasticsearch_role "role" {
    for_each = var.roles
    name    = each.key
    cluster = each.value.cluster

    dynamic "indices" {
        for_each = each.value.indices[*]
        content {
            names      = indices.value.names
            privileges = indices.value.privileges
        }
    }
}

########
# Create local users
########
resource elasticsearch_user "user" {
    for_each    = local.users
    username    = each.key
    full_name   = each.key
    password    = each.value.password
    roles       = each.value.roles
    depends_on  = [ elasticsearch_role.role ]
}

########
# Create roles mappings
########
resource elasticsearch_role_mapping "rm" {
    for_each = var.roles_mapping
    name     = each.key
    enabled  = "true"
    roles    = each.value.roles
    rules    = each.value.rules
    depends_on  = [ elasticsearch_role.role ]
}


########
# Manage license
########
resource elasticsearch_license "license" {
    count = var.license_key == "" ? 0 : 1
    use_basic_license = "false"
    license           = local.license
}

########
# Manage ILM policies
########
resource elasticsearch_index_lifecycle_policy "ilm" {
    for_each = var.ilm_policies
    name    = each.key
    policy  = file(each.value)
}

########
# Manage index templates
########
resource elasticsearch_index_template "it" {
    for_each    = var.index_template
    name        = each.key
    template    = file(each.value)
}


# Create snapshot repository
resource elasticsearch_snapshot_repository "sr" {
    for_each = var.snapshots_repository
    name	 = each.key
    type 	 = each.value.type
    settings = each.value.settings
}

# Snapshot lifecycle policy
resource elasticsearch_snapshot_lifecycle_policy "slp" {
    for_each = var.slm_policies
    name            = each.key
    snapshot_name   = each.value.name
    schedule 		= each.value.schedule
    repository      = each.value.repository
    configs         = each.value.settings
    retention       = each.value.retention
    depends_on = [ elasticsearch_snapshot_repository.sr ]
}