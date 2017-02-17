local parse = {}

function parse.split(str, separator, splits)
    local parts = {}
    local splitcount = 0
    local s = 1
    local e = 1

    for c in str:gmatch"." do
        if(c == separator) then
            table.insert(parts, str:sub(s, e-1))
            s = e +1
            splitcount = splitcount + 1
        end

        e = e +1

        if(splitcount == splits) then 
            e = 0
            break 
        end
    end

    table.insert(parts, str:sub(s, e -1))

    return parts
end

function parse.spliturl(url)
    local s, e = url:find("https?://")
    local protocol = "https"

    -- get protocol
    if(s) then
        protocol = parse.split(url:sub(s, e), ":", 1)[1]
        url = url:sub(e+1, -1)
    end

    -- separate host from request
    local parts = parse.split(url, "/", 1)

    -- get request
    local request = "/"
    if(parts[2] ~= nil and parts[2] ~= '') then 
        request = "/" .. parts[2]
    end
    

    -- separate host and port
    local host_port = parse.split(parts[1], ":", 1)

    -- get port
    local port
    if(host_port[2] == nil or host_port[2] == '') then
        if(protocol == "http") then port = "80"
        elseif(protocol == "https") then port = "443" end
    else
        port = host_port[2]
    end

    return protocol, host_port[1], port, request
end

return parse
