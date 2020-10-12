######## 
# Create roles
########

resource elasticsearch_role "monitor" {
    name    = "monitor"
    cluster = [
        "monitor",
        "read_ilm",
        "read_slm",
        "cluster:admin/slm/status",
        "cluster:admin/snapshot/get"
    ]
    indices {
        names       = ["*"]
        privileges  = [
            "view_index_metadata",
            "monitor"
        ]
    }
}





########
# Create local users
########
resource elasticsearch_user "monitoring_user" {
    username    = local.monitoring_user
    full_name   = local.monitoring_user
    password    = local.monitoring_password
    roles       = ["remote_monitoring_agent"]
}

########
# Create roles mappings
########
resource elasticsearch_role_mapping "admins" {
    name    = "admins"
    enabled = "true"
    roles   = ["superuser"]
    rules = <<EOF
{
    "field": {
    	"groups": "CN=HM_ELS_LOG_ADMINS,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
    }
}
EOF
}



resource elasticsearch_role_mapping "monitor" {
    name    = "monitor"
    enabled = "true"
    roles   = [elasticsearch_role.monitor.name]
    rules = <<EOF
{
    "field": {
    	"dn": "CN=cs.nagios,OU=Services,DC=HM,DC=DM,DC=AD"
    }
}
EOF
}

resource elasticsearch_role_mapping "graph" {
    name    = "graph"
    enabled = "true"
    roles   = ["superuser"]
    rules = <<EOF
{
    "field": {
    	"dn": "CN=cs.exprdkx1,OU=Services,DC=HM,DC=DM,DC=AD"
    }
}
EOF
}


########
# Manage license
########
resource elasticsearch_license "license" {
    use_basic_license = "false"
    license           = local.elasticsearch_license
}

########
# Manage ILM policies
########
resource elasticsearch_index_lifecycle_policy "ilm" {
    for_each = var.ilm_policies
    name    = each.key
    policy  = each.value
}

########
# Manage index templates
########
resource elasticsearch_index_template "socle" {
    name        = "template_socle"
    template    = file("file/index-template/template_socle.json")
}

resource elasticsearch_index_template "index_template" {
    for_each    = var.index_templates
    name        = each.key
    template    = each.value
}
