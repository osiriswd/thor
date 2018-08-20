#!/usr/bin/lua
local cjson = require 'cjson.safe'

local function stringsplit(str,delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local function etcd_response(api_end)
    local res = ngx.location.capture("/etcd/"..api_end,{
        method = ngx.HTTP_GET
    })
    return res
end

local function find_http_port(t)
    local http_ports={}
    local port_name="http"
    local http_port=t["spec"]["ports"][1]["port"]
    local i
    for i=1,table.maxn(t["spec"]["ports"]) do
        if (t["spec"]["ports"][i]["name"] == "http") or (t["spec"]["ports"][i]["name"] == "https") then
            http_port = t["spec"]["ports"][i]["port"]
            port_name = t["spec"]["ports"][i]["name"]
            i = i+1
        end
    end
    http_ports["name"] = port_name
    http_ports["port"] = http_port
    http_ports["ip"] = t["spec"]["clusterIP"]
    return http_ports
end

local function get_endpoint(api_end)
    local etcd_json = etcd_response(api_end)
    if etcd_json.status == 404 then
        return nil
    end
    return etcd_json.body
end

local function get_cache(api_end,exptime)
    local dict_cache = ngx.shared.k8sservices
    local res_cache,flags,stale = dict_cache:get_stale(api_end)
    local ntime = ngx.time()
    local res_obj
    if not res_cache then
        res_obj = get_endpoint(api_end)
        if not res_obj then
            return nil
        end
        ----make cache
        dict_cache:safe_set(api_end,res_obj,exptime,ntime)
        return res_obj
    end
    if stale then
        res_obj = get_endpoint(api_end)
        if not res_obj then
            return nil
        end
        ----make cache
        dict_cache:replace(api_end,res_obj,exptime,ntime)
        return res_obj    
    end
    if (flags+exptime-ntime) < 3 then
        local dict_lock = ngx.shared.thorlock
        local lock_key = api_end .. "_lock"
        ----obtain lock
        local get_lock,err = dict_lock:safe_add(lock_key,"1",3)
        if get_lock then
            ----renew cache
            res_obj = get_endpoint(api_end)
            if res_obj then
                dict_cache:replace(api_end,res_obj,exptime,ntime)
            end
            ----release lock
            local d = dict_lock:delete(lock_key)
        end
    end
    return res_cache
end

local rquri = ngx.var.request_uri
local orig_args = stringsplit(rquri,'/')
local args = {}
local args_len = 1
local i
----proxy
if #orig_args < 5 then
    ngx.status = 500
    ngx.say("{\"error\":\"need more args\"}")
    ngx.exit(500) 
    return
end

for i = 2,5 do
    args[i] = orig_args[i]
    args_len = args_len + string.len(args[i]) + 1
end

if args[2] ~= "namespaces" then
    ngx.status = 500
    ngx.say("{\"error\":\"need namespaces\"}")
    ngx.exit(500)   
    return
end
    
if args[3] == nil or args[3] == '' then
    ngx.status = 500
    ngx.say("{\"error\":\"need namespaces\"}")
    ngx.exit(500)
    return
end

if (args[4] == "services" and args[5] ~= nil and args[5] ~= '') then
    local namespace = args[3]
    local api_services = "v2/keys/registry/services/specs/"..namespace.."/"..args[5]
    local svc_json = get_cache(api_services,10)
    if not svc_json then
        ngx.status = 404
        ngx.say("{\"error\":\"service not exists\"}")
        ngx.exit(404)
        return
    end 
    local svc_t = cjson.decode(svc_json)
    local api_handler = string.sub(rquri,args_len,string.len(rquri))
    if api_handler == "" then
        api_handler = '/'
    end
    local http_ports = find_http_port(cjson.decode(svc_t["node"]["value"]))
    local upstream = http_ports["name"].."://"..http_ports["ip"]..":"..http_ports["port"]
    ngx.var.http_backend = upstream
    ngx.var.http_handler = api_handler
end
