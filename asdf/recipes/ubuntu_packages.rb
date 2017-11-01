package "automake"
package "autoconf"
package "build-essential"
package "git"
package "libffi-dev"
package "libglu1-mesa-dev"
package "libgl1-mesa-dev"
package "libncurses5-dev"
package "libpng3"
package "libreadline-dev"
package "libssl-dev"
package "libtool"
package "libwxgtk3.0-dev"
package "libssh-dev"
package "libyaml-dev"
package "libxslt-dev"
package "m4"
package "unixodbc-dev"
package "nodejs-legacy"
package "npm"		
package "rabbitmq-server"		
package "redis-server"

version = node["asdf"]["postgres_version"]
codename = node["asdf"]["release_apt_codename"]

apt_repository "apt.postgresql.org" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{codename}-pgdg"
  components ["main", version]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

package "postgresql-client-common"
package "postgresql-client-#{version}"
package "postgresql-common"		
package "postgresql-server-dev-#{version}"		
		
bash "install_brunch" do		
  cwd "/home/ubuntu"		
  code "npm install -g brunch"		
end