start-openshift-with-catalog:
	oc cluster up --service-catalog
	oc login -u system:admin
	oc adm policy add-cluster-role-to-user cluster-admin developer
	oc login -u developer -p developer
	oc project openshift
	oc adm policy add-cluster-role-to-group system:openshift:templateservicebroker-client system:unauthenticated system:authenticated
.PHONY: start-openshift-with-catalog

start-openshift:
	oc cluster up
	oc login -u system:admin
	oc adm policy add-cluster-role-to-user cluster-admin developer
	oc login -u developer -p developer
	oc project openshift
.PHONY: start-openshift

stop-openshift:
	oc cluster down
.PHONY: stop-openshift

install-templates:
	oc create -f imagestreams/infinispan-centos7.json || true
	oc create -f templates/infinispan-persistent.json || true
	oc create -f templates/infinispan-ephemeral.json || true
	oc import-image is/infinispan || true
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
	oc import-image is/infinispan || true
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
