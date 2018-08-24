# kubernetes-dse
Deploy DataStax Enterprise (DSE) cluster on a Kubernetes cluster

This project provides a set of sample Kubernetes yamls to provision DataStax Enterprise in a Kubernetes cluster environment on various cloud platforms for experimental only. It uses "default" namespace in Kubernetes and sample cloud provider's storage class definition. You would modify the yamls according to your own deployment requirements such as namespace, storage device type, cloud provider zone, etc.

#### Prerequisites:
* Tools including wget, kubectl have already been installed on your machine to execute our yamls.
* Kubernetes server's version is 1.8.x or higher. 

**Step One: Deploy the yamls set**

You can choose one of the following four deployment options.

#### 1. Running DSE + OpsCenter locally on a laptop/notebook
*This yamls set uses emptyDir as DataStax Enterprise data store.*
```
$ wget --quiet https://github.com/DSPN/kubernetes-dse/raw/master/local/dse-suite.yaml -O dse-suite-local.yaml
$ kubectl apply -f dse-suite-local.yaml
```

#### 2. Running DSE + OpsCenter on Azure Container Service (AKS) [sample]
*This yamls set uses kubernetes.io/azure-disk provisioner along with Premium_LRS storage type on Azure*
```
$ wget --quiet https://github.com/DSPN/kubernetes-dse/raw/master/aks/dse-suite.yaml -O dse-suite-aks.yaml
$ kubectl apply -f dse-suite-aks.yaml
```

#### 3. Running DSE + OpsCenter on Amazon Elastic Container Service (EKS) in us-west-2a [sample]
*This yamls set uses kubernetes.io/aws-ebs provisioner along with ext4 filesystem type and IOPS per GB rate 10 in us-west-2a.  You will need to modify the StorageClass definition if you plan to deploy in different AWS zone.* 
```
$ wget --quiet https://github.com/DSPN/kubernetes-dse/raw/master/eks/dse-suite.yaml -O dse-suite-eks.yaml
$ kubectl apply -f dse-suite-eks.yaml
```

#### 4. Running DSE + OpsCenter on Google Kubernetes Engine (GKE) [sample]
*This yamls set uses kubernetes.io/gce-pd provisioner along with pd-ssd persistent disk type*
```
$ wget --quiet https://github.com/DSPN/kubernetes-dse/raw/master/gke/dse-suite.yaml -O dse-suite-gke.yaml
$ kubectl apply -f dse-suite-gke.yaml
```

**Step Two: Access the DataStax Enterprise OpsCenter managing the newly created DSE cluster**

You can run the following command to monitor the status of your deployment.
```
$ kubectl get all
```
Then run the following command to view if the status of **dse-cluster-init-job** has successfully completed.  It generally takes about 10 minutes to spin up a 3-node DSE cluster.
```
$ kubectl get job dse-cluster-init-job
```
Once complete, you can access the DataStax Enterprise OpsCenter web console to view the newly created DSE cluster by pointing your browser at http://<svc/opscenter-ext-lb's EXTERNAL-IP>:8888

Use "kubectl get service opscenter-ext-lb -o yaml" to see EXTERNAL-IP of the loadBalancer

**Step Three: Tear down the DSE deployment**
```
$ kubectl delete -f dse-suite-<your cloud platform choice>.yaml (the same yaml file you used in step one above)
$ kubectl delete pvc -l app=dse (to remove the dynamically provisioned persistent volumes)
```

