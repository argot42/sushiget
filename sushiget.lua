#!/usr/bin/lua

local help = require "help"
local parse = require "parse"


if (not arg[1]) then 
    help.usage()
    return
end

for _,url in ipairs(arg) do
    -- get posts
    io.stdout:write("* fetching images: "); io.flush()
    local posts, image_n = help.getposts(url)
    local new_posts, new_image_n = posts, image_n
    print(image_n)

    while (true) do
        -- download and save images
        io.stdout:write("* downloading images: "); io.flush()
        local images_saved = help.download_images(url, posts)
        posts, image_n = new_posts, new_image_n
        print(images_saved)

        -- check for new posts
        print("* checking for new images")
        new_posts, new_image_n = help.getposts(url)

        -- discard already downloaded posts
        local extra_posts, extra_image_n = parse.filterposts(posts, new_posts)

        if (extra_image_n > 0) then
            io.stdout:write(extra_image_n .. "new images!\ndownload? [y/n] ")
            local r = io.stdin:read("*line")

            r = r:lower()
            if (r == 'n' or r == 'no') then break end
            
            posts, image_n = new_posts, new_image_n
        else 
            print("-no new images-")
            print("\nbye ❤")
            break -- end search
        end
    end
end
