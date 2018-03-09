# thor
Build image using:
docker build -t thor .

Create kubernetes deployments with thor.json, and create services with thor-svc.json.
Then you can access and PODs' HTTP services with Thor API:
http://THOR_IP:THOR_PORT/namespaces/NAMESPACE_NAME/services/SERVICE_NAME/(your-service-handler)

And you can also access kubernete api with Thor API too:
http://THOR_IP:THOR_PORT/manage/
