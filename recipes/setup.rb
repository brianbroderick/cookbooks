# frozen_string_literal: true

include_recipe "chef_postgres::log_output"

chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

node.default["chef_postgres"]["server_name"] = "default"
node.default["chef_postgres"]["release_apt_codename"] = node["lsb"]["codename"]
node.default["chef_postgres"]["version"] = "9.6"
node.default["chef_postgres"]["workload"] = "oltp"

codename = node["chef_postgres"]["release_apt_codename"]
version = node["chef_postgres"]["version"]

node.default["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] = true
node.default["chef_postgres"]["pg_config"]["data_directory"] = if node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"]
                                                                 "/mnt/data/postgresql/#{version}/main"
                                                               else
                                                                 "/var/lib/postgresql/#{version}/main"
                                                               end

_, pg_pass, _ = ::Chef::Provider::DbUser.call(node, "pg_login")
admin_user, admin_pass, admin_is_generated = ::Chef::Provider::DbUser.call(node, "admin_login")
repl_user, repl_pass, _ = ::Chef::Provider::DbUser.call(node, "repl_login")

node.default["chef_postgres"]["vars"]["admin_user"] = admin_user
node.default["chef_postgres"]["vars"]["admin_pass"] = admin_pass
node.default["chef_postgres"]["vars"]["admin_is_generated"] = admin_is_generated
node.default["chef_postgres"]["vars"]["repl_user"] = repl_user
node.default["chef_postgres"]["vars"]["repl_pass"] = repl_pass

::Chef::Log.info("** Setting up apt_repository to get access to the latest PG versions **")

apt_repository "apt.postgresql.org" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{codename}-pgdg"
  components ["main", version]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

apt_repository "debian" do
  uri "http://ftp.us.debian.org/debian"  
  components ["testing", "main", "contrib"]  
  deb_src true
  action :add
end

::Chef::Log.info("** Installing Postgres **")

package "software-properties-common"    
package "build-essential"
package "pkg-config"
package "git"
package "libproj-dev"
package "liblwgeom-dev"
package "libprotobuf-c-dev=1.2.1-1+b1"

# package "postgresql-#{version}"
# package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"

service "stop_postgres" do
  action :stop
  service_name "postgresql"
  notifies :run, "ruby_block[log_stop_pg]", :before
end

directory node["chef_postgres"]["pg_config"]["data_directory"] do
  action :create
  owner "postgres"
  group "postgres"
  mode "0700"
  recursive true
  only_if { node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] }
  notifies :run, "ruby_block[log_data_directory]", :before
end

template "pg_hba.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/pg_hba.conf"
  source "pg_hba_conf.erb"
  variables({ config: { repl_user: repl_user } })
  notifies :run, "ruby_block[log_copy_files]", :before
end

template "postgresql.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/postgresql.conf"
  source "postgresql_conf.erb"
  variables({ config: { optimization: ::Chef::Provider::PgConfig.call(node),
                        repl: { cluster_type: node["chef_postgres"]["pg_config"]["cluster_type"],
                                pg_node: node["chef_postgres"]["pg_config"]["pg_node"] } } })
end

directory "/backups/base_backup" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  notifies :run, "ruby_block[log_backup_directory]", :before
end
