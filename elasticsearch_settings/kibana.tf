# Create spaces
resource kibana_user_space "old" {
    name = "old"
    description = "Display old data and old dashboard"
    disabled_features = [
        "maps",
        "graph",
        "monitoring",
        "ml",
        "apm",
        "infrastructure",
        "logs",
        "siem",
        "uptime"
    ]
}

# Create roles
resource kibana_role "default" {
  name = "default"
  kibana {
    base    = ["read"]
    spaces  = ["default", kibana_user_space.old.name]
  }
}


# Create index patterns
resource kibana_object "index_pattern_ecs" {
  name            = "index_pattern_ecs"
  data            = file("file/index-pattern/ecs.ndjson")
  space           = "default"
  deep_reference	= "true"
  export_objects {
	  id    = "ecs-*"
	  type  = "index-pattern"
  }
}



