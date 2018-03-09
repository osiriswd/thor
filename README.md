# thor
Build image:

docker build -t thor .

Create kubernetes deployments with thor.json, create services with thor-svc.json.
Find the NodePort of thor via kubernetes-dashboard, then you can access any PODs' HTTP services with Thor:

http://${NODE_IP}:${THOR_PORT}/namespaces/${NAMESPACE_NAME}/services/${SERVICE_NAME}/(your-service-handler)

And you can also access kubernete api with Thor too:

http://${NODE_IP}:${THOR_PORT}/manage/

For single port kubernetes services, thor will attemp proxy_pass to the ClusterIP:Port.
For multiple ports services, thor looks for the field .spec.ports[].name="http" and proxy_pass to it, otherwise it will proxy_pass to the first port in kubernetes services.

