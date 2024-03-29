nioorg-dns-server role
=========

[![Build Status](https://github.com/nioorg/role-dns-server/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/nioorg/role-dns-server/actions/workflows/build.yml)

This Ansible role installs and configures a DNS server on the machine. The default configuration installs both `Stubby`, to encrypt the DNS traffic over Internet (DNS over TLS), and `Pi-hole` to perform AD Blocking, local DNS resolution and caching

Any of those components can be disabled using the appropriate variable(`stubby_enabled` or `pihole_enabled`).

Requirements
------------

To execute this role you need the following system packages:

* docker
* docker-compose
* pip

And the following pip packages, to use Docker from the Ansible role:

* docker
* docker-compose

Role Variables
--------------

All varibales are optional.

The following is the list of the available variables and its default values:

```yaml
dns_server_path: "/home/{{ ansible_user }}/dns_server"
# List of subnets the server will be listening on.
# By default it listens for connections from everywhere.
dns_server_listening:
  - 0.0.0.0/0
# Public DNS servers to use if you want to bypass stubby.
# Only used when stubby_enabled: false.
public_dns1: 1.1.1.1
public_dns2: 1.0.0.1

stubby:
  enabled: true
  # Openssl
  openssl_version: "openssl-1.1.1f"
  openssl_sha256: "186c6bfe6ecfba7a5b48c47f8a1673d0f3b0e5ba2e25602dd23b629975da3f35"
  openssl_source: "https://www.openssl.org/source/"
  openssl_opgp: "8657ABB260F056B1E5190839D9C4D26D0E604491"
  # Stubby client version
  getdns_version: "v1.7.0"
  # Stubby configuration
  config:
    # GETDNS_TRANSPORT_TLS - GETDNS_TRANSPORT_UDP - GETDNS_TRANSPORT_TCP
    TRANSPORT_PROTOCOL: "GETDNS_TRANSPORT_TLS"
    # For Strict use        GETDNS_AUTHENTICATION_REQUIRED
    # For Opportunistic use GETDNS_AUTHENTICATION_NONE
    USAGE_PROFILE: "GETDNS_AUTHENTICATION_REQUIRED"
    EDNS0_PAD: 128
    EDNS0_ECS1: 1
    EDNS0_ECS1_TIMEOUT: 10000
    DISTRIBUTED_QUERIES: 1

pihole:
  enabled: true
  image: pihole/pihole:latest
  http_port: 8001
```

Dependencies
------------

This role doesn't have any direct dependency.

Despite that, it is recomended to use the following roles before running this one:
* [common](https://github.com/nioorg/role-common) - to perform the basic configuration of the server
* [docker](https://github.com/geerlingguy/ansible-role-docker) - to install docker and docker-compose
* [pip](https://github.com/geerlingguy/ansible-role-pip.git) - to install pip and the docker packages

Example Playbook
----------------

Here is an example playbook using the default variables:

```yaml
- hosts: all
  roles:
    - dns_server
```

Here is an example playbook where we restrict the ip addresses the server listens on, for security reasons:

```yaml
- hosts: all
  roles:
    - role: dns_server
      vars:
        dns_server_listening:
          - 192.168.0.0/16
```

In the following example we use the roles recomended in the [Dependencies](https://github.com/nioorg/role-dns-server#dependencies) section to completely setup the server:

```yaml
- hosts: all
  roles:
    - role: common
    - role: pip
      become: yes
      vars:
        pip_install_packages:
          - name: docker
          - name: docker-compose
    - role: docker
      become: yes
    - role: dns_server
```

License
-------

See LICENSE

Author Information
------------------

https://github.com/iuginP/
