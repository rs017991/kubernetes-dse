# Initial Setup
1. Create **dse** namespace: ```kubectl create -f dse-namespace.yml```
2. Update your context to use the new namespace: ```kubectl config set-context mycontext -n dse```
3. Make sure you are using that context, whatever it is called: ```kubectl config use-context mycontext```
4. **identity.jks** dummy file must be replaced with a keystore that contains a new private key.
5. **identity.pkcs8.pem** dummy file must be replaced with the private key, exported without a password
6. **identity.x509.pem** dummy file must be replaced with the certificate of the new private key
7. **trusted.x509.pem** dummy file must be replaced with a certificate of an appropriate link in the trust chain of the new keypair
8. **cacerts** dummy file must be replaced with a certificate store that contains the above x509 certs
9. Upload the configuration: ```kubectl create configmap dse-config --from-file=cassandra.yaml --from-file=dse.yaml --from-file=cqlshrc --from-file=identity.x509.pem --from-file=trusted.x509.pem --from-file=jmxremote.access --from-file=jvm.options --from-file=nodetool-ssl.properties --from-file=datastax-agent-env.sh```
10. Upload the secrets: ```create secret generic dse-secrets --from-file=.keystore=identity.jks --from-file=identity.pkcs8.pem --from-file=cacerts --from-file=jmxremote.password```

# Creating the Cluster
```kubectl apply -f ../eks/dse-suite.yaml```

# Interacting with the Cluster

## Some Basic Cassandra operations
* Nodetool Commands: ```kubectl exec dse-0 -- nodetool --ssl -u cassandra -pw cassandra status```
* Interactive cqlsh: ```kubectl exec -ti dse-0 -- cqlsh dse-0 -u cassandra -p cassandra```
* Run local cql file: ```cat myschema.sql | kubectl exec -i dse-0 -- cqlsh dse-0 -u cassandra -p cassandra```
* View logs: ```kubectl logs dse-0```

## Connecting to OpsCenter
1. Find the IP Address of any k8s node (it doesn't matter whether OpsCenter is actually running on that node). Ex:
```
$ kubectl get no
NAME                                          STATUS    ROLES     AGE       VERSION
ip-10-123-45-67.us-west-2.compute.internal   Ready     <none>    6d        v1.9.6
```
2. After deriving the IP address from the hostname, hit it at port 30888 in a web browser, ex: ```http://10.123.45.67:30888```
3. Since the init script doesn't support TLS or Authentication, you will need to manually upload the cluster json:
    * ```curl -Uri http://10.123.45.67:30888/cluster-configs -Method POST -InFile cluster.json```

## Connecting via CQL outside of k8s
1. Find the IP Address of any k8s node (it doesn't matter whether DSE is actually running on that node). Ex:
```
$ kubectl get no
NAME                                          STATUS    ROLES     AGE       VERSION
ip-10-123-45-67.us-west-2.compute.internal   Ready     <none>    6d        v1.9.6
```
2. After deriving the IP address from the hostname, it can be connected via any CQL driver on port 30943 (provided TLS is set up on the client)
    * cqlsh example: ```cqlsh --ssl 10.123.45.67 30943 -u cassandra -p cassandra```
    * java example:
        ```java
        Cluster.builder().addContactPoint("10.123.45.67").withPort(30943).withCredentials(...).withSSL(...)/*etc*/.build().connect();
        ```
## Destroying the Cluster
* To destroy OpsCenter/Cassandra/Services: ```kubectl delete -f ../eks/dse-suite.yaml```
* To destroy the data volumes (non-recoverable!): ```kubectl delete pvc -l app=dse```

Note that neither of the above will delete the configMaps/secrets/namespace
