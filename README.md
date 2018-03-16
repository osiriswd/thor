# Thor
Instead of using Ingress, Thor dynamically discover and proxy to Kubernetes services, stored kubernetes apiserver's response in Nginx shared_dict as caches.

Build image:

docker build -t thor .

Create kubernetes deployments with thor.json, create services with thor-svc.json.
Find the NodePort of thor via kubernetes-dashboard, then you can access any HTTP services with Thor:

http://${NODE_IP}:${THOR_PORT}/namespaces/${NAMESPACE_NAME}/services/${SERVICE_NAME}/(your-service-handler)

like:

http://10.0.29.21:31599/namespaces/kube-system/services/kubernetes-dashboard/

And you can also access kubernete api with Thor too(don't forget adding the http header "Authorization: Bearer $API_TOKEN"):

http://${NODE_IP}:${THOR_PORT}/manage/

----------------------------
Name the port "http" in your kubernetes services as a convenience.
For single port kubernetes services, thor attemps proxy_pass to the ClusterIP:Port.
For multiple ports services, thor looks for the field .spec.ports[].name="http" in kubernetes services and proxy_pass to it, otherwise it will proxy_pass to the first port listed in kubernetes services' .spec.ports array.

