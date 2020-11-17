######## 
# Create roles
########
resource elasticsearch_role "logstash_writer" {
    name    = "logstash_writer"
    cluster = ["manage_index_templates", "monitor"]
    indices {
        names       = ["ecs-*", "logstash-*"]
        privileges  = ["write", "delete", "create_index", "read"]
    }
}

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

resource elasticsearch_role "kibana_reader" {
    name    = "kibana_reader"
    cluster = ["monitor"]
    indices {
        names       = ["ecs-log-*", "ecs-inventory", "ecs-esb-*", "ecs-backup-*", "logstash-inventory", "logstash-backup-*", "logstash-log-*", "logstash-esb-*"]
        privileges  = ["read"]
    }
}

resource elasticsearch_role "kibana_reader_system" {
    name = "kibana_reader_system"
    cluster = ["monitor"]
    indices {
        names       = ["ecs-system-*", "logstash-system-*"]
        privileges  = ["read"]
    }
}

########
# Create local users
########
resource elasticsearch_user "logstash" {
    username    = local.logstash_user
    full_name   = "logstash"
    password    = local.logstash_password
    roles       = [elasticsearch_role.logstash_writer.name]
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

resource elasticsearch_role_mapping "users" {
    name    = "users"
    enabled = "true"
    roles   = [elasticsearch_role.kibana_reader.name, kibana_role.default.name, "reporting_user"]
    rules = <<EOF
{
    "any": [
        {
            "field": {
            	"groups": "CN=HM_ELS_LOG_USERS,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
            }
        },
        {
            "field": {
            	"groups": "CN=HM_ELS_LOG_ADMINS,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
            }
        },
        {
            "field": {
            	"groups": "CN=HM_ELS_LOG_SYSTEM,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
            }
        },
        {
            "field": {
            	"dn": "CN=cs.dcnstix1,OU=Services,DC=HM,DC=DM,DC=AD"
            }
        },
        {
            "field": {
            	"dn": "CN=cs.dcnstir1,OU=Services,DC=HM,DC=DM,DC=AD"
            }
        }
    ]
}
EOF
}

resource elasticsearch_role_mapping "users_system" {
    name    = "users-system"
    enabled = "true"
    roles   = [elasticsearch_role.kibana_reader_system.name, kibana_role.default.name, "reporting_user"]
    rules = <<EOF
{
    "any": [
        {
            "field": {
            	"groups": "CN=HM_ELS_LOG_SYSTEM,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
            }
        },
        {
            "field": {
            	"groups": "CN=HM_ELS_LOG_ADMINS,OU=Droits Applicatifs,OU=HM,OU=Groupes Utilisateurs,DC=HM,DC=DM,DC=AD"
            }
        }
    ]
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

resource elasticsearch_index_template "backup" {
    name        = "template_backup"
    template    = file("file/index-template/template_backup.json")
}

resource elasticsearch_index_template "esb" {
    name        = "template_esb"
    template    = file("file/index-template/template_esb.json")
}

resource elasticsearch_index_template "log" {
    name        = "template_log"
    template    = file("file/index-template/template_log.json")
}

resource elasticsearch_index_template "kube" {
    name        = "template_kube"
    template    = file("file/index-template/template_kube.json")
}

resource elasticsearch_index_template "system_raw" {
    name        = "template_system_raw"
    template    = file("file/index-template/template_system_raw.json")
}

resource elasticsearch_index_template "system_access" {
    name        = "template_system_access"
    template    = file("file/index-template/template_system_access.json")
}

resource elasticsearch_index_template "ecs" {
    name        = "template_ecs"
    template    = file("file/index-template/template-ecs.json")
}

resource elasticsearch_index_template "filebeat" {
    name        = "template_filebeat"
    template    = file("file/index-template/template-filebeat.json")
}

resource elasticsearch_index_template "winlogbeat" {
    name        = "template_winlogbeat"
    template    = file("file/index-template/template-winlogbeat.json")
}

resource elasticsearch_index_template "index_template" {
    for_each    = var.index_templates
    name        = each.key
    template    = each.value
}



# Create snapshot repository
resource elasticsearch_snapshot_repository "snapshot" {
    name		= "snapshot"
    type 		= "fs"
    settings 	= {
	    "location" =  "/mnt/snapshot"
    }
}

# Snapshot lifecycle policy
resource elasticsearch_snapshot_lifecycle_policy "kibana" {
    name            = "policy_kibana"
    snapshot_name   = "<daily-snap-{now/d}>"
    schedule 		    = "0 30 1 * * ?"
    repository      = elasticsearch_snapshot_repository.snapshot.name
    configs         = <<EOF
{
	"indices": [".kibana_*"],
	"ignore_unavailable": false,
	"include_global_state": false
}
EOF
    retention       = <<EOF
{
    "expire_after": "7d",
    "min_count": 5,
    "max_count": 10
} 
EOF
}