name 'labpages'
maintainer 'Julien Bianchi'
maintainer_email 'contact@jubianchi.fr'
version '1.0.0'
supports 'debian', '>= 6.0.0'
license 'MIT'

depends "git"
depends "apt"

provides "labpages::directories"
provides "labpages::install"
provides "labpages::configure"
provides "labpages::nginx"
provides "labpages::redis"
provides "labpages::bundle"
provides "labpages::dev"

