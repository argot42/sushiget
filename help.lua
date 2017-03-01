package.cpath = package.cpath .. ';/usr/local/lib/lua/5.1/?.so'

local sslrequest = require "sslrequest"
local cjson = require "cjson"
local parse = require "parse"

local help = {}

function help.usage()
    print(arg[0] .. " <url>+")
end

function help.getposts (url)
    -- change html to json and get parts of url
    local protocol, host, port, path = parse.spliturl(parse.convert_url(url))
    
    -- make the request
    local response = assert(sslrequest.ssl_get(host,
                                          port,
                                          string.format("GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", path, host),
                                          1024,
                                          64),
                        "HTTP request failed")

    local header, body = parse.separate_http(response)    -- separate body from header

    -- if response is not OK raise error
    header = parse.headerlist(header)
    if (header["status"][2] == "200") then return {}, 0 end

    local thread = cjson.decode(body)

    local posts_with_images = {}
    local count = 0

    -- get all images from posts
    for _,post in pairs(thread["posts"]) do
        if (post["filename"]) then
            table.insert(posts_with_images, {post["filename"], post["tim"], post["ext"]})
            count = count + 1

            if (post["extra_files"]) then
                for _, extra in pairs(post["extra_files"]) do
                    table.insert(posts_with_images, {extra["filename"], extra["tim"], post["ext"]})
                    count = count + 1
                end
            end
        end
    end

    return posts_with_images, count
end

function help.download_images (url, posts)
    local count = 0

    for _,post in ipairs(posts) do
        local image_url = parse.get_img_url(url, post[2] .. post[3])
        local _, host, port, path = parse.spliturl(image_url)

        -- get image
        local response = sslrequest.ssl_get(host,
                                         port,
                                         string.format("GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", path, host),
                                         1024,
                                         64)

        if (response) then
            local header, image = parse.separate_http(response)

            header = parse.headerlist(header)
            -- check if response is OK
            if (header["status"][2] == "200") then

                -- save file with original filename
                local file = io.open(post[1] .. post[3], 'w')
                file:write(image)
                count = count + 1

            end
        end
    end

    return count
end

return help
