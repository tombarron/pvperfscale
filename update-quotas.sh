#!/bin/bash

source /home/stack/adminrc

manila quota-class-update --gigabytes -1 --shares -1 default
manila quota-delete --share-type default
manila quota-delete --user-id openshift
manila quota-delete --tenant-id openshift

source /home/stack/userrc
echo 'Removed share/gigabytes quotas for openshift.'
manila absolute-limits
