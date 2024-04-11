# Vagrantfile and Scripts to Automate Kubernetes Setup using Kubeadm

The original project is [techiescamp Github][github-techiescamp-vagrant-kubeadm-kubernetes].

I added:

01. The possibility to work with more *master* nodes.
02. The use of one extra *worker* node by default (lower the value from `settings.yaml`).
03. The use of a private *registry* with some images by default.
    - The images are the most common ones: python, mongo, node, wordpress, nginx, httpd, etc.
    - Images used in Kubernetes lab to learn k8s security.
04. An additional script, `use-local-registry.sh`, to convert remote images to local ones.
05. Provision for `docker` and other scripts.
    - Even though `docker` is not necessary, it is useful for some projects, such as Kubernetes GOAT.

## Setup Prerequisites

1. Working Vagrant setup
2. Working VirtualBox
3. 11 GiB + RAM workstation as the VMs use 3 vCPUS and 4+ GB RAM

## For MAC/Linux Users

The latest version of Virtualbox for Mac/Linux can cause issues.

Create/edit the `/etc/vbox/networks.conf` file and add the following to avoid any network-related issues.

<pre>* 0.0.0.0/0 ::/0</pre>

or run below commands

```shell
sudo mkdir -p /etc/vbox/
echo "* 0.0.0.0/0 ::/0" | sudo tee -a /etc/vbox/networks.conf
```

So that the host only networks can be in any range, not just 192.168.56.0/21 as described here:
https://discuss.hashicorp.com/t/vagrant-2-2-18-osx-11-6-cannot-create-private-network/30984/23

## Bring Up the Cluster

To provision the cluster, execute the following commands.

```shell
git clone https://github.com/gnunez88/vagrant-kubeadm-kubernetes.git
cd vagrant-kubeadm-kubernetes
vagrant up
```

### More Provisioning

If you want to add more provisioning, create a valid `bash` script in the `scripts/` directory,
namely `custom.sh`, and add this line to the desired machine in the `Vagrantfile` file:

```ruby
node.vm.provision "<name>", type: "shell", path: "scripts/custom.sh"
```

Where `<name>` can be any name you want. If the provision script was created after
the machine creation, it can be provision with, using the next command:

```shell
vagrant provision <machine-name> --provision-with <name>
```

## Set Kubeconfig file variable

```shell
cd vagrant-kubeadm-kubernetes
cd configs
export KUBECONFIG=$(pwd)/config
```

or you can copy the config file to .kube directory.

```shell
cp config ~/.kube/
```

## Install Kubernetes Dashboard

The dashboard is automatically installed by default, but it can be skipped by commenting out the dashboard version in _settings.yaml_ before running `vagrant up`.

If you skip the dashboard installation, you can deploy it later by enabling it in _settings.yaml_ and running the following:

```shell
vagrant ssh -c "/vagrant/scripts/dashboard.sh" master01
```

## Kubernetes Dashboard Access

To get the login token, copy it from _config/token_ or run the following command:

```shell
kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}"
```

Make the dashboard accessible:

```shell
kubectl proxy
```

Open the site in your browser:

```shell
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
```

## Shutdown the cluster

```shell
vagrant halt
```

## Restart the cluster

```shell
vagrant up
```

## Destroy the cluster

```shell
vagrant destroy -f
```

# Registry

By default a new virtual machine named `registry` will be added to the VirtualBox group.
This will be intended to keep a private Docker registry.

The images added to the registry (by default) are:

## See images available

To see the images available, you can make request to `registry:5000` from within any
node in the cluster, like this:

```shell
curl -sS http://registry:5000/v2/_catalog | jq '.repositories[]'
```

From outside the cluster, you have to substitute `registry` with the IP of the
virtual machine.

There is a web interface through port `8080/tcp`:

```text
http://<registry-ip>:8080/
```

Thanks to the [Docker Registry Frontend project][github-konradkleine-docker-registry-frontend]

## Some k8s Projects

### Security Projects

Some interesting Kubernetes projects to play around to understand better Kubernetes security are:

- [Kuberetes GOAT][github-madhuakula-kubernetes-goat]
- [badPods][github-BishopFox-badPods]
- [WrongSecrets][github-OWASP-wrongsecrets]

## Add more images

To add more images to the registry, follow the next steps:

01. Access the *registry*: `vagrant ssh registry`
02. Download a valid Docker image: `sudo docker image pull <image>`
03. Tag the image: `sudo docker image tag <image> registry:5000/<image>`
04. Push the image to the registry: `sudo docker image push registry:5000/<image>`
05. Remove the local pulled images: `sudo docker image rm <image> registry:5000/<image>`

If the image is created by yourself, just omit the first two steps.



[docker-konradkleine-docker-registry-frontend]: https://hub.docker.com/r/konradkleine/docker-registry-frontend/
[github-BishopFox-badPods]: https://github.com/BishopFox/badPods
[github-madhuakula-kubernetes-goat]: https://github.com/madhuakula/kubernetes-goat
[github-OWASP-wrongsecrets]: https://github.com/OWASP/wrongsecrets
[github-techiescamp-vagrant-kubeadm-kubernetes]: https://github.com/techiescamp/vagrant-kubeadm-kubernetes
