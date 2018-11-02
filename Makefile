_TEST_PROJECT = myproject

install-templates:
	oc create -f templates/infinispan-persistent.yaml
	oc create -f templates/infinispan-ephemeral.yaml
.PHONY: install-templates

clear-templates:
	oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-ephemeral || true
	oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=infinispan-persistent || true
	oc delete template infinispan-ephemeral || true
	oc delete template infinispan-persistent || true
.PHONY: clear-templates

update-templates:
	oc replace -f templates/infinispan-persistent.yaml
	oc replace -f templates/infinispan-ephemeral.yaml
.PHONY: update-templates
