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

    -- separate host from path
    local parts = parse.split(url, "/", 1)

    -- get path
    local path = "/"
    if(parts[2] ~= nil and parts[2] ~= '') then 
        path = "/" .. parts[2]
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

    return protocol, host_port[1], port, path -- protocol, host, port, path
end

function parse.separate_http(r)
    local s, e = r:find("%s\r\n")
    return r:sub(0, s-1), r:sub(e+1, -1) -- header, body
end

function parse.convert_url(url)
    return url:gsub("html$", "json")
end

function parse.get_img_url(url, file)
    local board = url:match("/(%w*)/res/")

    return url:gsub(string.format("/%s/res/.*$", board), string.format("/%s/src/%s", board, file))
end

function parse.filterposts(posts, new_posts)
    local number_of_images=0
    local filtered_posts = {}
    local ison = false

    for _,new_post in ipairs(new_posts) do
        for _,post in ipairs(posts) do
            if (new_post["tim"] == post["tim"]) then
                ison = true
                break
            end
        end

        if (not ison) then
            table.insert(filtered_posts, new_post)
            number_of_images = number_of_images + 1
        end

        ison = false
    end

    return filtered_posts, number_of_images
end

return parse
