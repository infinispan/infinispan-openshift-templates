_TEST_PROJECT = myproject

start-openshift-with-catalog:
	oc cluster up --service-catalog
	oc project $(_TEST_PROJECT)
.PHONY: start-openshift-with-catalog

stop-openshift:
	oc cluster down
.PHONY: stop-openshift

_grant_cluster_admin_permissions:
	oc login -u system:admin
	oc adm policy add-cluster-role-to-user cluster-admin developer
	oc login -u developer -p developer
.PHONY: stop-_grant_cluster_admin_permissions

_relist-template-service-broker: _grant_cluster_admin_permissions
	# This one is very hacky - the idea is to increase the relist request counter by 1. This way we ask the Template
	# Service Broker to refresh all templates. The rest of the complication is due to how Makefile parses file.
	RELIST_TO_BE_SET=`expr $(shell oc get ClusterServiceBroker/template-service-broker --template={{.spec.relistRequests}}) + 1` && \
	oc patch ClusterServiceBroker/template-service-broker -p '{"spec":{"relistRequests": '$$RELIST_TO_BE_SET'}}'
.PHONY: _relist-template-service-broker

install-templates-in-openshift-namespace: _relist-template-service-broker _grant_cluster_admin_permissions
	oc create -f imagestreams/infinispan-centos7.json -n openshift || true
	oc create -f templates/infinispan-persistent.json -n openshift || true
	oc create -f templates/infinispan-ephemeral.json -n openshift || true
.PHONY: install-templates-in-openshift-namespace

install-templates:
	oc create -f imagestreams/infinispan-centos7.json || true
	oc create -f templates/infinispan-persistent.json || true
	oc create -f templates/infinispan-ephemeral.json || true
.PHONY: install-templates

clear-templates:
	oc delete is infinispan || true
	oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-ephemeral || true
	oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-persistent || true
.PHONY: clear-templates

update-templates:
	oc replace -f imagestreams/infinispan-centos7.json
	oc replace -f templates/infinispan-persistent.json
	oc replace -f templates/infinispan-ephemeral.json
.PHONY: update-templates

test-persistent:
	oc process infinispan-persistent -p NAMESPACE=$(shell oc project -q) | oc create -f -
.PHONY: test-persistent

test-ephemeral:
	oc process infinispan-ephemeral -p NAMESPACE=$(shell oc project -q) | oc create -f -
.PHONY: test-ephemeral

export-configuration-for-persistent-template:
	oc create configmap transactions-configuration --from-file=./configurations/cloud-persistent.xml --output=json
.PHONY: export-configuration-for-persistent-template

export-configuration-for-ephemeral-template:
	oc create configmap transactions-configuration --from-file=./configurations/cloud-ephemeral.xml --output=json
.PHONY: export-configuration-for-ephemeral-template
