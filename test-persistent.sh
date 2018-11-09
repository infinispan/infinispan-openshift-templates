#!/usr/bin/env bash

set -e

TEST_USER=test
TEST_PASSWORD=test

oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-persistent || true
oc delete template infinispan-persistent || true


oc create -f infinispan-persistent.yaml


oc new-app infinispan-persistent \
  -p APPLICATION_USER=$TEST_USER \
  -p APPLICATION_PASSWORD=$TEST_PASSWORD


# TODO http should be exposed by default
oc expose svc/infinispan-persistent-app-http


isPodReady() {
  oc get pod -l application=infinispan-persistent-app -o jsonpath="{.items[0].status.containerStatuses[0].ready}"
}

getPodStatus() {
  oc get pod -l application=infinispan-persistent-app -o jsonpath="{.items[0].status.containerStatuses[0].state}"
}

waitForReady() {
  ready="false"
  while [ "$ready" != "true" ];
  do
    ready=$(isPodReady)
    status=$(getPodStatus)
    echo "Pod: ready=${ready},status=${status}"
    sleep 10
  done
}

waitForReady


getRouteHost() {
  oc get route/infinispan-persistent-app-http -o jsonpath="{.spec.host}"
}

printf "\n--> Delete previous values, if present\n"
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  -X DELETE \
  $(getRouteHost)/rest/default/stuff

printf "\n--> Store a key/value pair\n"
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  -X POST \
  -H 'Content-type: text/plain' \
  -d 'test' \
  $(getRouteHost)/rest/default/stuff

printf "\n--> Retrieve key\n"
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  -w "\n" \
  $(getRouteHost)/rest/default/stuff


printf "\n--> Scale down...\n"
oc scale statefulset infinispan-persistent-app --replicas=0

sleep 5

printf "\n--> Scale up...\n"
oc scale statefulset infinispan-persistent-app --replicas=1

sleep 5

waitForReady


printf "\n--> Retrieve key\n"
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  -w "\n" \
  $(getRouteHost)/rest/default/stuff
