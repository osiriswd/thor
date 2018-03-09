# thor
Build image:

docker build -t thor .

Create kubernetes deployments with thor.json, create services with thor-svc.json.
Find the NodePort of thor via kubernetes-dashboard, then you can access any PODs' HTTP services with Thor:

http://THOR_IP:THOR_PORT/namespaces/NAMESPACE_NAME/services/SERVICE_NAME/(your-service-handler)

And you can also access kubernete api with Thor too:

http://THOR_IP:THOR_PORT/manage/
