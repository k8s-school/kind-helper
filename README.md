# kind-travis-ci

Simple example to setup continous integration for an application running inside Kubernetes.

Show how to run [kind](https://github.com/kubernetes-sigs/kind) inside [Travis-CI](https://travis-ci.org/fjammes/kind-travis-ci)

[![Build
Status](https://travis-ci.org/fjammes/kind-travis-ci.svg?branch=master)](https://travis-ci.org/fjammes/kind-travis-ci)

## Pre-requisites

* Create a github repository dedicated to  continous integration for a given application, for example: https://github.com/GITHUB_ACCOUNT/GITHUB_REPOSITORY
* Active github repository for travis-ci, see https://travis-ci.org//GITHUB_ACCOUNT/GITHUB_REPOSITORY
* Create a container image for the given application and push it to a container registry

## Setup

* Add `kind` directory and `.travis.yml` file to your git repository
* Update files `run.sh` and `test.sh` so that it run and test a given application in a given version
