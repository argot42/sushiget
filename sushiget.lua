#!/usr/bin/lua

package.cpath = package.cpath .. ';/usr/local/lib/lua/5.1/?.so'

local help = require "help"


if (not arg[1]) then 
    help.usage()
    return
end

for _,url in ipairs(arg) do
    -- get posts
    local posts, image_n = help.getposts(url)

    while (true) do
        -- download and save images
        local images_saved = help.download_images(url, posts)

        -- check for new posts
        local new_posts, new_image_n = help.getposts(url)

        if (new_image_n > image_n) then
            io.stdout:write("new images!\ndownload them [y/n] ")
            local r = io.stdin:read("*line")

            r = r:lower()
            if (r == 'n' or r == 'no') then break end
            
            posts, image_n = new_posts, new_image_n
        else 
            break
        end
    end
end
