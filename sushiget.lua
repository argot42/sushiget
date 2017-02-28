#!/usr/bin/lua

local help = require "help"
local parse = require "parse"


if (not arg[1]) then 
    help.usage()
    return
end

for _,url in ipairs(arg) do
    -- get posts
    local posts, image_n = help.getposts(url)
    local new_posts, new_image_n = posts, image_n

    while (true) do
        -- download and save images
        local images_saved = help.download_images(url, posts)
        posts, image_n = new_posts, new_image_n

        -- check for new posts
        new_posts, new_image_n = help.getposts(url)

        -- discard already downloaded posts
        local extra_posts, extra_image_n = parse.filterposts(posts, new_posts)

        if (extra_image_n > 0) then
            io.stdout:write("new images!\ndownload them [y/n] ")
            local r = io.stdin:read("*line")

            r = r:lower()
            if (r == 'n' or r == 'no') then break end
            
            posts, image_n = new_posts, new_image_n
        else 
            break -- end search
        end
    end
end
