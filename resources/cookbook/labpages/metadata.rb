name             'labpages'
maintainer       'Julien Bianchi'
maintainer_email 'contact@jubianchi.fr'
version          '1.0.0'
license          'MIT'

supports         'debian', '>= 6.0.0'

depends          'apt'

recipe           'labpages', ''
recipe           'labpages::nginx', ''
recipe           'labpages::ruby', ''
