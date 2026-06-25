# 1. Start from your specified base image
FROM pivert/luantiserver-pg-prom:5.16.1 AS base

# Set a working directory inside the image
WORKDIR /app

# 2. Copy all repository contents (including submodules) into the image
COPY . /var/lib/luanti/.minetest/mods

# 3. Copy the unzipped Luanti package into its specific location inside the image
# (Adjust /app/games/minetest_game to the exact path your application expects)
COPY ./minetest_game_extracted /var/lib/luanti/.minetest/games/minetest_game

# (Optional) Clean up the build context artifact inside the image so it doesn't duplicate
RUN rm -rf /var/lib/luanti/.minetest/mods/minetest_game_extracted
