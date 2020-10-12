variable "spaces" {
    description = "Map of kibana spaces to create"
    type        = map(object({
        description       = string
        source_space      = string
        groups_write      = list(string)
        groups_read       = list(string)
        disabled_features = list(string)
        copy_objects      = list(object({
            id   = string
            type = string
        }))
    }))
}


