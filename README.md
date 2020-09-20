[<img src="http://k8s-school.fr/images/logo.svg" alt="K8s-school Logo, expertise et formation Kubernetes" height="50" />](https://k8s-school.fr)

# kind-travis-ci

Helpers to install [kind] on a workstation or inside a virtual machine launch by a  CI/CD platform.

[![Build
Status](https://travis-ci.com/k8s-school/kind-travis-ci.svg?branch=master)](https://travis-ci.com/k8s-school/kind-travis-ci)

Support kind v0.9.0 and k8s v1.18

## Run kind on a workstation, in two lines of code

```shell
git clone https://github.com/k8s-school/kind-travis-ci

# Run a 3 nodes k8s cluster with kind 
./kind-travis-ci/kind/k8s-create.sh

# Run a single node k8s cluster with kind
./kind-travis-ci/kind/k8s-create.sh -s

# Run a k8s cluster with canal CNI, in order to enable NetworkPolicies inside kind
./kind-travis-ci/kind/k8s-create.sh -c
```

## Run kind inside Travis-CI


Check this **[tutorial: build a Kubernetes CI with Kind](https://k8s-school.fr/resources/en/blog/k8s-ci/)** in order to learn how to run [kind](https://github.com/kubernetes-sigs/kind) inside [Travis-CI](https://travis-ci.org/k8s-school/kind-travis-ci).

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
