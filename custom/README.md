# Initial Setup
1. Create **dse** namespace: ```kubectl create -f dse-namespace.yml```
2. Update your context to use the new namespace: ```kubectl config set-context mycontext -n dse```
3. Make sure you are using that context, whatever it is called: ```kubectl config use-context mycontext```
4. Upload the configuration: ```kubectl create configmap dse-config --from-file=cassandra.yaml```
5. **identity.jks** dummy file must be replaced with a keystore that contains a new private key.
6. **cacerts** dummy file must be replaced with a certificate store that trusts the new private key.
7. Upload these as secrets: ```kubectl create secret generic dse-secrets --from-file=identity.jks --from-file=cacerts```

# Creating the Cluster
```kubectl apply -f ../eks/dse-suite.yaml```

# Interacting with the Cluster

## Some Basic Cassandra operations
* Nodetool Commands: ```kubectl exec dse-0 -- nodetool status```
* Interactive cqlsh: ```kubectl exec -ti dse-0 -- cqlsh dse-0```
* Run local cql file: ```cat myschema.sql | kubectl exec -i dse-0 -- cqlsh dse-0```
* View logs: ```kubectl logs dse-0```

## Connecting to OpsCenter
1. Find the IP Address of any k8s node (it doesn't matter whether OpsCenter is actually running on that node). Ex:
```
$ kubectl get no
NAME                                          STATUS    ROLES     AGE       VERSION
ip-10-123-45-67.us-west-2.compute.internal   Ready     <none>    6d        v1.9.6
```
2. After deriving the IP address from the hostname, hit it at port 30888 in a web browser, ex: ```http://10.123.45.67:30888```

## Connecting via CQL outside of k8s
1. Find the IP Address of any k8s node (it doesn't matter whether DSE is actually running on that node). Ex:
```
$ kubectl get no
NAME                                          STATUS    ROLES     AGE       VERSION
ip-10-123-45-67.us-west-2.compute.internal   Ready     <none>    6d        v1.9.6
```
2. After deriving the IP address from the hostname, it can be connected via any CQL driver on port 30943 (provided TLS is set up on the client)
    * cqlsh example: ```cqlsh --ssl 10.123.45.67 30943```
    * java example:
        ```java
        Cluster.builder().addContactPoint("10.123.45.67").withPort(30943).withSSL(...)/*etc*/.build().connect();
        ```
## Destroying the Cluster
* To destroy OpsCenter/Cassandra/Services: ```kubectl delete -f ../eks/dse-suite.yaml```
* To destroy the data volumes (non-recoverable!): ```kubectl delete pvc -l app=dse```

Note that neither of the above will delete the configMaps/secrets/namespace
