# Tmux Session Manager
Manage your tmux sessions config and existance

## Parameters

* prefix - Canonicalized version of this string will prefix any global classes. This should be unique in identifying the activation of the bundle.
* bundle_home - Path to sketch directory (not used by the sketch)
* tmux_bin - Path to tmux binary
* su_bin - Path to su bindary
* command - Command to optionally execute when launching a new session
* session_name - Name of tmux session your promising does or does not exist
* context_remove_session - Context in which the named session should not exist
* runas - Username the named session is promised for
* tmux_config - List of tmux configuration options to be written to tmux_config_path and used for session launch
* context_remove_config - Context in which the configuration file should not exist. Note this does not prohibit session launch
* context_conf_emptyfirst - Context in which tmux_config promises the entire contents of tmux_config_path

