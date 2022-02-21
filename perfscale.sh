#!/bin/bash

function create_pvc {
    local SC=$1
    local INSTANCE=$2

    oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc$INSTANCE
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: $SC
EOF

}

function create_pod {
    local INSTANCE=$1

    oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod$INSTANCE
spec:
  restartPolicy: Never
  containers:
   - image: gcr.io/google_containers/busybox
     command:
       - "/bin/sh"
       - "-c"
       - "while true; do echo \$(hostname) \$(date) >> /mnt/test/\$(hostname); sleep 10; done"
     name: busybox
     volumeMounts:
       - name: myvol
         mountPath: /mnt/test
  volumes:
    - name: myvol
      persistentVolumeClaim:
        claimName: pvc$INSTANCE
        readOnly: false
EOF
}
    
function get_data_point {
    local SC=$1
    local LOW=$2
    local HIGH=$3
    local i=0
    
    local start=`date +%s`

    for i in $(seq $LOW $HIGH); do
        echo "i:$i"
        create_pvc $SC $i
        create_pod $i
    done

    while oc get pod --no-headers=True | grep -v "Running" ; do
        echo 'waiting for all pods to come up'
    done

    echo 'all pods are up now'

    local end=`date +%s`
    local runtime=$((end-start))
    echo "$SC,$HIGH,$runtime" >> times.csv
}


function cleanup {
    local SC=$1
    local LOW=$2
    local HIGH=$3
    local i=0
    
    local start=`date +%s`

    for i in $(seq $LOW $HIGH); do
      echo $i
      oc delete pvc pvc$i &
      oc delete pod pod$i &
    done

    while oc get pod --no-headers=True | grep -v  'No Resources found'; do
        echo 'waiting for all pods to be cleaned up'
    done
    while oc get pvc --no-headers=True | grep -v  'No Resources found'; do
        echo 'waiting for all pvcs to be cleaned up'
    done

    if [[ $SC = *"manila"* ]]; then
	while manila list | grep -Ev '^\+|ID'; do
            echo 'waiting for all backend shares to be removed'
	done
    else
        while cinder list | grep -Ev '^\+|ID'; do
            echo 'waiting for all backend volumes to be removed'
        done
    fi
    echo 'all pods and pvcs have been cleaned up'

    local end=`date +%s`
    local runtime=$((end-start))
    echo "$SC,$HIGH,$runtime" >> teardown_times.csv

}

START=$1
INTERVAL=$2
LIMIT=$3

mv times.csv times.csv.old 2> /dev/null
echo 'Storage Class,Number of Pods,Seconds' > times.csv
mv teardown_times.csv teardown_times.csv.old 2> /dev/null
echo 'Storage Class,Number of Pods,Seconds' > teardown_times.csv

for STORAGE_CLASS in 'standard' 'standard-csi' 'csi-manila-default' ; do
    echo "---------  $STORAGE_CLASS ------"
    for v in $(seq $START $INTERVAL $LIMIT); do
	echo "v: $v"
        get_data_point $STORAGE_CLASS 1 $v
        cleanup  $STORAGE_CLASS 1 $v
    done
done

