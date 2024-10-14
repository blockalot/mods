#!/bin/bash

# enable wind mills for technic plus
sed -i 's/enable_wind_mill = "false"/enable_wind_mill = "true"/' technic/technic/config.lua
