[<img src="http://k8s-school.fr/images/logo.svg" alt="K8s-school Logo, expertise et formation Kubernetes" height="50" />](https://k8s-school.fr)

# kind-helper

Helper to install Kubernetes clusters, based on [kind], on any Linux system. Allow to easily setup:
- multi-nodes cluster
- set CNI plugin and enable NetworkPolicies
- enable PodSecurityPolicy adminission control plugin.
 
Can be used for VMs launched by a  CI/CD platform, including [Github Action](https://github.com/k8s-school/kind-helper/actions?query=workflow%3A"CI")

[![CI Status](https://github.com/k8s-school/kind-helper/workflows/CI/badge.svg?branch=master)](https://github.com/k8s-school/kind-helper/actions?query=workflow%3A"CI")

Support kind v0.10.0 and k8s v1.20

## Run kind on a workstation, in two lines of code

```shell
git clone https://github.com/k8s-school/kind-helper

# Run a single node k8s cluster with kind
./kind-helper/k8s-create.sh -s

# Run a 3 nodes k8s cluster with kind 
./kind-helper/k8s-create.sh

# Run a k8s cluster with Canal CNI, in order to enable NetworkPolicies inside kind
./kind-helper/k8s-create.sh -c canal

# Run a k8s cluster with Cilium CNI
./kind-helper/k8s-create.sh -c cilium

# Run a k8s cluster with Calico CNI
./kind-helper/k8s-create.sh -c calico

# Delete the kind cluster
./kind-helper/k8s-delete.sh

```

## Run kind inside Travis-CI


Check this **[tutorial: build a Kubernetes CI with Kind](https://k8s-school.fr/resources/en/blog/k8s-ci/)** in order to learn how to run [kind](https://github.com/kubernetes-sigs/kind) inside [Travis-CI](https://travis-ci.org/k8s-school/kind-helper).

### Pre-requisites

* Create a github repository dedicated to  continous integration for a given application, for example: https://github.com/<GITHUB_ACCOUNT>/<GITHUB_REPOSITORY>
* Active github repository for travis-ci, see https://travis-ci.org/<GITHUB_ACCOUNT>/<GITHUB_REPOSITORY>
* Create a container image for the given application and push it to a container registry
 
### Setup

* Add `kind` directory and `.travis.yml` file to your git repository
* Update files `run.sh` and `test.sh` so that it run and test a given application in a given version


[kind]:https://github.com/kubernetes-sigs/kind

## Additional resource

* [Blog post: running Kubernetes in the ci pipeline](https://www.loodse.com/blog/2019-03-12-running-kubernetes-in-the-ci-pipeline-/)
