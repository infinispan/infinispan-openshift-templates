install-templates:
	oc create -f imagestreams/infinispan-centos7.json || true
	oc create -f templates/infinispan-persistent.json || true
	oc create -f templates/infinispan-ephemeral.json || true
	oc import-image is/infinispan
.PHONY: install-templates

update-templates:
	oc replace -f imagestreams/infinispan-centos7.json
	oc replace -f templates/infinispan-persistent.json
	oc replace -f templates/infinispan-ephemeral.json
	oc import-image is/infinispan
.PHONY: update-templates

test-persistent:
	oc process infinispan-persistent | oc create -f -
.PHONY: test-persistent

test-ephemeral:
	oc process infinispan-ephemeral | oc create -f -
.PHONY: test-ephemeral

export-configuration-for-template:
	oc create configmap transactions-configuration --from-file=./configurations/cloud-persistent.xml --output=json
.PHONY: export-configuration-for-template
