LabPages - Hacking
==================

You should find everything you need in the repository to get started and hack LabPages in less than 30 minutes.
Every thing is included:

* A packer template to get a Debian/Gitlab Vagrant base-box
* A Vagrantfile with everything to provision a dev. box
* Some test data and repositories
* A nginx virtual host
* Managed ```/etc/hosts``` files
*...

All you have to do is [install Vagrant](http://downloads.vagrantup.com/tags/v1.2.7) and open a terminal:

```sh
$ git clone https://github.com/jubianchi/labpages.git
$ cd labpages

# If you have a vagrant 1.2.* installed, you can use the pre-built base-box
$ make up MIRROR=http://static.jubianchi.fr/boxes/wheezy.box

# Otherwise you'll need to build it yourself using packer
$ make up

# ...

$ vagrant ssh
```

After that everything should be up and running, except the LabPages service which you will have to start manually:

```sh
# Inside the vagrant box
$ sudo service labpages start
# or
$ cd /vagrant && rackup -p 8080
```

Inside this box, you will also find three cloned repositories with ```gl-pages``` branches in ```/home/vagrant/repositories```.
You can directly commit and push on these repositories to test LabPages.

