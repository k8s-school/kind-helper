[<img src="http://k8s-school.fr/images/logo.svg" alt="K8s-school Logo, expertise et formation Kubernetes" height="50" />](https://k8s-school.fr)

# kind-travis-ci

Helpers to install [kind] on a workstation or inside travis-ci.

[![Build
Status](https://travis-ci.com/k8s-school/kind-travis-ci.svg?branch=master)](https://travis-ci.com/k8s-school/kind-travis-ci)

## Run kind on a workstation

```shell
git clone https://github.com/k8s-school/kind-travis-ci
./kind-travis-ci/kind/k8s-create.sh
```

## Run kind inside Travis-CI

How to run [kind](https://github.com/kubernetes-sigs/kind) inside [Travis-CI](https://travis-ci.org/k8s-school/kind-travis-ci)
Check this blog post: https://k8s-school.fr/resources/blog/2-k8s-ci in order to get a detailed example.


### Pre-requisites

* Create a github repository dedicated to  continous integration for a given application, for example: https://github.com/<GITHUB_ACCOUNT>/<GITHUB_REPOSITORY>
* Active github repository for travis-ci, see https://travis-ci.org/<GITHUB_ACCOUNT>/<GITHUB_REPOSITORY>
* Create a container image for the given application and push it to a container registry
 
### Setup

* Add `kind` directory and `.travis.yml` file to your git repository
* Update files `run.sh` and `test.sh` so that it run and test a given application in a given version


[kind]:https://github.com/kubernetes-sigs/kind

## Additional resources

* [Tutorial: build a Kubernetes CI with Kind](https://k8s-school.fr/resources/en/blog/k8s-ci/)
* [Blog post: running Kubernetes in the ci pipeline](https://www.loodse.com/blog/2019-03-12-running-kubernetes-in-the-ci-pipeline-/)
