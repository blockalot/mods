Clone with ```git clone --recurse-submodules git@github.com:blockalot/mods.git```  
Add new mods by running: ```git submodule add <mod-git-url>```  
Pull latest changes ```git pull --recurse-submodules```
For faster pulling use, this may result in notabug returning 503s tho ```git pull --recurse-submodules --jobs=5```


## Serve media via HTTP
This repo includes a script to collect the media of the mods in a folder in a Luanti specific format. This folder can then be served e.g. via Nginx to improve the fetching via the Luanti client. https://docs.luanti.org/for-server-hosts/remote-media/

To collect the media simply run `bash collect_media.sh`
