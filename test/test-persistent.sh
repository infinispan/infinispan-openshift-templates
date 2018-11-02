#!/usr/bin/env bash

set -e

TEST_USER=test
TEST_PASSWORD=test

oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-persistent || true
oc delete template infinispan-persistent || true


oc create -f templates/infinispan-persistent.json


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

#getRouteHost() {
#  oc get route/infinispan-persistent-app-http -o jsonpath="{.spec.host}"
#}
#
## Store via HTTP REST
#curl -v \
#  -u $TEST_USER:$TEST_PASSWORD \
#  -X POST \
#  -H 'Content-type: text/plain' \
#  -d 'test' \
#  $(getRouteHost)/rest/default/stuff
#
#
## Retrieve via HTTP REST
#curl -v \
#  -u $TEST_USER:$TEST_PASSWORD \
#  $(getRouteHost)/rest/default/stuff
#
#
## Scale down
#oc scale statefulset infinispan-persistent-app --replicas=0
#
## Scale up
#oc scale statefulset infinispan-persistent-app --replicas=1
#
#waitForReady
#
## Retrieve via HTTP REST
#curl -v \
#  -u $TEST_USER:$TEST_PASSWORD \
#  $(getRouteHost)/rest/default/stuff
