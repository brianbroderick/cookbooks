include_recipe "asdf::log_output"
include_recipe "asdf::ubuntu_packages"
include_recipe "asdf::install_asdf"
include_recipe "asdf::install_versions"
include_recipe "asdf::globals"
include_recipe "asdf::install_elixir_tools"
include_recipe "asdf::code_deploy"
include_recipe "asdf::etc_environment"
include_recipe "asdf::cron"
