require "yaml"
vagrant_root = File.dirname(File.expand_path(__FILE__))
settings = YAML.load_file "#{vagrant_root}/settings.yaml"

# Environment

IP_SECTIONS = settings["network"]["control_ip"].match(/^([0-9.]+\.)([^.]+)$/)
# First 3 octets including the trailing dot:
IP_NW = IP_SECTIONS.captures[0]
# Last octet excluding all dots:
IP_START = Integer(IP_SECTIONS.captures[1])
# Registry IP address
IP_REGISTRY = settings["network"]["registry_ip"]
DNS_REGISTRY = settings["network"]["registry_name"]
# Gap between the first master node IP and the first worker node IP
IP_GAP = 50
NUM_WORKER_NODES = settings["nodes"]["workers"]["count"]
NUM_MASTER_NODES = settings["nodes"]["master"]["count"]

# Cluster

Vagrant.configure("2") do |config|
  config.vm.provision "hosts", type: "shell",
  env: { 
    "IP_NW" => IP_NW,
    "IP_START" => IP_START,
    "NUM_WORKER_NODES" => NUM_WORKER_NODES,
    "IP_REGISTRY" => IP_REGISTRY,
    "DNS_REGISTRY" => DNS_REGISTRY
    },
  inline: <<-SHELL
    apt-get update -y
    for i in `seq 1 ${NUM_MASTER_NODES}`; do
      echo "$IP_NW$((IP_START + i)) master0${i}" >> /etc/hosts
    done
    for i in `seq 1 ${NUM_WORKER_NODES}`; do
      echo "$IP_NW$((IP_START + IP_GAP + i)) node0${i}" >> /etc/hosts
    done
    echo "$IP_REGISTRY $DNS_REGISTRY" >> /etc/hosts
  SHELL

  if `uname -m`.strip == "aarch64"
    config.vm.box = settings["software"]["box"] + "-arm64"
  else
    config.vm.box = settings["software"]["box"]
  end
  config.vm.box_check_update = true

  # Registry
  config.vm.define "registry" do |registry|
    registry.vm.hostname = DNS_REGISTRY
    registry.vm.network "private_network", ip: IP_REGISTRY
    registry.vm.provider "virtualbox" do |vb|
      vb.cpus = settings["nodes"]["registry"]["cpu"]
      vb.memory = settings["nodes"]["registry"]["memory"]
      if settings["cluster_name"] and settings["cluster_name"] != ""
        vb.customize ["modifyvm", :id, "--groups", ("/" + settings["cluster_name"])]
      end
    end
    registry.vm.provision "docker", type: "shell", path: "scripts/docker.sh"
    registry.vm.provision "service", type: "shell", path: "scripts/registry-service.sh"
    registry.vm.provision "reverse-proxy", type: "shell",
      env: {
        "COUNTRY" => settings["certificates"]["registry"]["country"],
        "STATE" => settings["certificates"]["registry"]["state"],
        "ORG" => settings["certificates"]["registry"]["org"],
        "OU" => settings["certificates"]["registry"]["ou"],
        "CN" => settings["certificates"]["registry"]["cn"],
        "IP_REGISTRY" => IP_REGISTRY,
        "DNS_REGISTRY" => DNS_REGISTRY
      },
      path: "scripts/reverse-proxy.sh"
    registry.vm.provision "images", type: "shell", path: "scripts/registry-images.sh"
  end

  # Master nodes
  (1..NUM_MASTER_NODES).each do |i|

    config.vm.define "master0#{i}" do |master|
      master.vm.hostname = "master0#{i}"
      master.vm.network "private_network", ip: IP_NW + "#{IP_START + i}"
      if settings["shared_folders"]
        settings["shared_folders"].each do |shared_folder|
          master.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
        end
      end
      master.vm.provider "virtualbox" do |vb|
        vb.cpus = settings["nodes"]["master"]["cpu"]
        vb.memory = settings["nodes"]["master"]["memory"]
        if settings["cluster_name"] and settings["cluster_name"] != ""
          vb.customize ["modifyvm", :id, "--groups", ("/" + settings["cluster_name"])]
        end
      end
      master.vm.provision "shell",
        env: {
          "DNS_SERVERS" => settings["network"]["dns_servers"].join(" "),
          "ENVIRONMENT" => settings["environment"],
          "KUBERNETES_VERSION" => settings["software"]["kubernetes"],
          "KUBERNETES_VERSION_SHORT" => settings["software"]["kubernetes"][0..3],
          "OS" => settings["software"]["os"]
        },
        path: "scripts/common.sh"
      master.vm.provision "shell",
        env: {
          "CALICO_VERSION" => settings["software"]["calico"],
          "CONTROL_IP" => IP_NW + "#{IP_START + i}",
          "POD_CIDR" => settings["network"]["pod_cidr"],
          "SERVICE_CIDR" => settings["network"]["service_cidr"]
        },
        path: "scripts/master.sh"
    end

  end

  # Worker nodes
  (1..NUM_WORKER_NODES).each do |i|

    config.vm.define "node0#{i}" do |node|
      node.vm.hostname = "node0#{i}"
      node.vm.network "private_network", ip: IP_NW + "#{IP_START + IP_GAP + i}"
      if settings["shared_folders"]
        settings["shared_folders"].each do |shared_folder|
          node.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
        end
      end
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = settings["nodes"]["workers"]["cpu"]
        vb.memory = settings["nodes"]["workers"]["memory"]
        if settings["cluster_name"] and settings["cluster_name"] != ""
          vb.customize ["modifyvm", :id, "--groups", ("/" + settings["cluster_name"])]
        end
      end
      node.vm.provision "shell",
        env: {
          "DNS_SERVERS" => settings["network"]["dns_servers"].join(" "),
          "ENVIRONMENT" => settings["environment"],
          "KUBERNETES_VERSION" => settings["software"]["kubernetes"],
          "KUBERNETES_VERSION_SHORT" => settings["software"]["kubernetes"][0..3],
          "OS" => settings["software"]["os"]
        },
        path: "scripts/common.sh"
      node.vm.provision "script", type: "shell", path: "scripts/node.sh"
      node.vm.provision "docker", type: "shell", path: "scripts/docker.sh"
      node.vm.provision "trust-registry", type: "shell",
        env: {
          "DNS_REGISTRY" => DNS_REGISTRY
        },
        path: "scripts/trust-registry.sh"

      # Only install the dashboard after provisioning the last worker (and when enabled).
      if i == NUM_WORKER_NODES and settings["software"]["dashboard"] and settings["software"]["dashboard"] != ""
        node.vm.provision "dashboard", type: "shell", path: "scripts/dashboard.sh"
      end
    end

  end
end 

