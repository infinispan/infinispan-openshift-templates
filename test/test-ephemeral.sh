#!/usr/bin/env bash

set -e

TEST_USER=test
TEST_PASSWORD=test

oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-ephemeral || true
oc delete template infinispan-ephemeral || true


oc create -f templates/infinispan-ephemeral.yaml


oc new-app infinispan-ephemeral \
  -p APPLICATION_USER=$TEST_USER \
  -p APPLICATION_PASSWORD=$TEST_PASSWORD


# TODO http should be exposed by default
oc expose svc/infinispan-app-http


isPodReady() {
  oc get pod -l application=infinispan-app -o jsonpath="{.items[0].status.containerStatuses[0].ready}"
}

getPodStatus() {
  oc get pod -l application=infinispan-app -o jsonpath="{.items[0].status.containerStatuses[0].state}"
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
  oc get route/infinispan-app-http -o jsonpath="{.spec.host}"
}

# Store via HTTP REST
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  -X POST \
  -H 'Content-type: text/plain' \
  -d 'test' \
  $(getRouteHost)/rest/default/stuff


# Retrive via HTTP REST
curl -v \
  -u $TEST_USER:$TEST_PASSWORD \
  $(getRouteHost)/rest/default/stuff
