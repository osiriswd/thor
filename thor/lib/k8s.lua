local k8s = {}

function k8s.api_response(self,api_end)
	----read token
	file = io.open("/var/run/secrets/kubernetes.io/serviceaccount/token", "r")
	token = file:read()
	file:close()
	ngx.req.set_header("Authorization","Bearer "..token)
	local res = ngx.location.capture("/gateway/"..api_end,{
			method = ngx.HTTP_GET
	})
	return res
end
return k8s
