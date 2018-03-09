#!/usr/bin/lua
package.path =  package.path .. ';' .. ngx.var.BASE_PATH .. '/lib/?.lua;'

local stringlib = require 'char'
local k8s = require 'k8s'
local cjson = require 'cjson.safe'
local rquri = ngx.var.request_uri
local orig_args = stringlib:stringsplit(rquri,'/')
local args = {}
local args_len = 1

function find_http_port(t)
        local http_port=t["spec"]["ports"][1]["port"]
        for i=1,table.maxn(t["spec"]["ports"]) do
                if t["spec"]["ports"][i]["name"] == "http" then
                        http_port = t["spec"]["ports"][i]["port"]
                        i = i+1
                end
        end
        return http_port
end

function get_cache(api_end,exptime)
        local dict_cache = ngx.shared.k8sservices
        local res_cache,flags = dict_cache:get(api_end)
        local ntime = os.time()
        local res_obj

        if not res_cache then
                res_obj = k8s:api_response(api_end)
                if res_obj.status == 200 then
                        dict_cache:safe_set(api_end,res_obj.body,exptime,ntime)
                        return res_obj.body
                end
        else
        if (flags+exptime-ntime) < 3 then
                local dict_lock = ngx.shared.thorlock
                local lock_key = api_end .. "_lock"
                ----obtain lock
                local get_lock,err = dict_lock:safe_add(lock_key,"1",3)
                if get_lock then
                        ----make cache
                        res_obj = k8s:api_response(api_end)
                        if res_obj.status == 200 then
                                dict_cache:safe_set(api_end,res_obj.body,exptime,ntime)
                        end
                        ----release lock
                        local d = dict_lock:delete(lock_key)
                end
        end
        end
        return res_cache
end


if #orig_args < 5 then
		ngx.status = 500
		ngx.say("{\"error\":\"need more args\"}")
		ngx.exit(500) 
else
        for i = 2,5 do
                        args[i] = orig_args[i]
        args_len = args_len + string.len(args[i]) + 1
        end
        if args[2] ~= "namespaces" then
				ngx.status = 500
				ngx.say("{\"error\":\"need namespaces\"}")
				ngx.exit(500) 		
                else
                if args[3] == nil then 
                        namespace = ''
                else
                        namespace = args[3]
                        if args[3] == nil or args[3] == '' then
					ngx.status = 500
					ngx.say("{\"error\":\"need namespaces\"}")
					ngx.exit(500) 	
                        else
                        if (args[4] == "services" and args[5] ~= nil and args[5] ~= '') then
                                local KUBERNETES = ngx.var.K8S_SERVICE_HOST .. "/" .. ngx.var.K8S_SERVICE_PORT
                                local api_services = "https/"..KUBERNETES.."/api/v1/namespaces/"..namespace.."/services/"..args[5]
                                local svc_json = get_cache(api_services,10)
                                if not svc_json                                                                                   
                                then                     
                                        ngx.status = 404
					ngx.say("{\"error\":\"service not exists\"}")
                                        ngx.exit(404)                                                 
                                else 
                                        svc_t = cjson.decode(svc_json)
                                        local api_handler = string.sub(rquri,args_len,string.len(rquri))
                                        if api_handler == "" then        
                                                        api_handler = '/'
                                        end
                                        local upstream = svc_t["spec"]["clusterIP"]..":"..find_http_port(svc_t)
                                        ngx.var.http_backend = upstream
                                        ngx.var.http_handler = api_handler
                                end
                        end
                        end
                end
        end
end