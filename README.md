RP
==

## Requires Alpha 1 Release 14!

RP could be described as some sort of modding framework. It works around current limitations and bugs of the game and provides mod authors with a few helpful functions to make their life easier (or in some cases, even enables useful modding in the first place). 

I've already released a bunch of (simple) mods using this framework, they are [listed below](#example-mods).

## Features
* Able to run server sided mods (where most of the stuff happens right now; perhaps I just haven't found the right way to access it though).
* Mods can have dependencies (and other ordering functions, i.e. "load mod X before mine")
* Every RP mod can be completely independent and can be shipped as an individual smod file. This allows authors to create mods with as much RP influence as they want. For users, this means you can simply drag-and-drop files into your mods directory to enable them, and delete/rename them to get rid of them.
* Hooks and proxies in lua allow multiple mods to alter the same area without conflicting with each other. It's kind of managing.
* Logging features for lua and JS make debugging easier (... or in JS' case, I think even possible).
* A simple-to-use config function allows mods to allow customization without caring about loading/validating their settings.

# Installation and usage (for users)
1. Download rp.smod [here][rp.smod].
2. Put it into your `Stonehearth/mods` directory.
3. Put any RP mod into `Stonehearth/mods`.
4. You're good to go!

Note that mods that build upon this framework will require you to install it (or perhaps a certain version of it). The framework itself does very little on it's own, practically nothing that you should notice.

If any mod you will install uses configuration files, they will be located at `Stonehearth/mods/config/` (due to current limitations). The folder and these files might not exist. If you create this directory, Stonehearth will likely complain in its log files that config is not a valid mod, should that bother you, [download this manifest.json][manifest.json] and put it into the config folder.

After the installation, you might see a few black flashing windows whenever you start Stonehearth. That's RP's current way of finding mods. If you are familiar with the command line, it's merely executing two `dir` commands (one for directories, one for files).

# For developers
Until I get a real documentation, here's a few things about RP and its mods:

* Feel free to unzip any of my smod files. They're not compiled and the lua is somewhat documented.
* Check `rp/api.lua`, `rp/server_init.lua` and `rp/client_init.lua` for the functions that RP defines.
* In order to have your mod recognized by RP, your mod needs to have a `rp` section in its `manifest.json`. Check my mod's manifests to get a few examples about it. The following entries in `rp` are currently supported:
 * `server_init`: Path to the file (relative to your mod directory) that should be executed once RP requires you to initialize the server side of your mod. This setting is optional. If it is omitted, RP assumes your mod has no server side.
 * `client_init`: The same as `server_init`, but for the client side.
 * `required`: Either a string or an array of strings. This is a (list of) mod(s) that need to be loaded before your mod. Use this to make changes to other mods or depend upon them. If a dependency is not found, the mod will not be loaded. `stonehearth`, `radiant` and `rp` will always be loaded before your mod and do not count as mods.
 * `requested`: Like `required`, but less strict. You simply request a (list of) mod(s) to be present. Any present mod will be loaded prior to yours; but your mod will still be loaded even if any of them is missing.
* If you decide to pack your mod into a smod file, the smod file has to be named exactly like the folder inside it (i.e. your mod folder). Otherwise, RP will not find your mod.
* RP will add two new log files, called `stonehearth_mod.log` (client) and `stonehearth_mod_server.log` (server). Whenever you use `rp.log`, `print` or `io.write` (`io.output` in general), it will end up there. Errors can also end up there (instead of the `stonehearth.log`) and usually provide some tracebacks so you know what went wrong.
* `rp.load_config` allows you to (easily) create and validate config files (for an example, see _sized workers_ or `rp/api.lua` itself). Recommended location for config files is `mods/config/[your mod name].json`.
* If you want to keep folders of your developed mods without having them loaded (or don't want to load them at all, even if they are smod files), you can use `disabled_mods` in `config/rp.json` to prevent them from loading. An example [rp.json can be found here][rp.json]. Mods that are disabled are treated as if they would not exist, even if another mod depends upon them.

# Example mods
Also, don't sue me on the names, I'm a programmer, not a writer. The "For developers:" section simply lists what could be of interest to a developer (because it's using a feature of RP, or has adapted something very common, or something like that) and can be skipped if you aren't going to develop stuff yourself.

* [Sized People][sized_people]: Randomly re-sizes your workers at the beginning to create a bit of variation.
* [Test World][test_world]: Instead of generating a huge world, it's just generating a simple tile (about 1/25th of the normal size). Loads extremely fast and should work on weaker computers too, but you might end up on a tile without any resources.
* [Workforce][workforce]: Allows you to spawn more workers using the camp standard.
* [Silence][silence]: Disables game music in both the menu and the game.
* [Lucky Worker][lucky_worker]: More of a joke mod. The first worker will always be a man, the others will be women. Might hurt productivity a bit.
* [Merge Names][merge_names]: More of a proof-of-concept, this will always use two first names and two last names and combine them, to get names like "Jessdara Brightwellburlyhands".

All these mods are [also available on GitHub](https://github.com/Quit/RP-Mods)

# Troubleshooting, terms and conditions
RP, including all mods that I have created and linked in this thread are released under the **MIT License** (except those parts that I did not create, such as `table.show` or partially rewritten Radiant functions). The next part should be common sense, but better safe than sorry: **I kindly ask you to not re-upload any of my content anywhere else.** Installing it should be easy enough, so just link to this thread. No hot linking please. You are however (as stated by the license) free to build your own mods based on mine and release them, as long as you give proper credit (a link to this repos and mentioning it somewhere in the source is more than enough!)

**As mods are very experimental** (and I had to work around quite a few things) **keep in mind that using mods can produce bugs that are not present in the normal version.** (Just like it's possible that mods are fixing stuff, too (I'm looking at you once again, `personality_serivce`). **Don't report bugs with mods to anyone but the mod authors**. Or me, maybe it's my fault. For all I know, the framework could have quite a few bugs.

Now that we've done the ugly part, let's get to the "May I take your hat, Sir" part.

If you are asking yourself why there's a few black boxes popping up and immediately disappearing when you are starting Stonehearth now, that's RP's way of finding your mods. Currently, there is no other way to do that, so I'm kind of resorting to good ol' `dir`. This is not dangerous nor a malfunction, this is the intended function. Feel free to check [load_mods.lua](load_mods.lua) if you don't believe me ;)

If you run into an issue while using this mod (and that issue wasn't there before), chances are I've messed up. RP redirects its output to a new log file, called "stonehearth_mod.log" (client) or "stonehearth_mod_server.log" (server). If you think there's something wrong with RP or any of these mods, please provide an accurate description and attach the logs (upload them to pastebin/codepad/somewhere similar). This means: `stonehearth.log` + `stonehearth_mod.log` + `stonehearth_mod_server.log`. The latter two should be in the same directory as your `stonehearth.log`.


[rp.smod]: https://dl.dropboxusercontent.com/u/44230457/sh/rp.smod
[manifest.json]: https://raw.github.com/Quit/RP-Mods/master/config/manifest.json
[rp.json]: https://raw.github.com/Quit/RP-Mods/master/config/rp.json
[sized_people]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/2
[test_world]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/3
[workforce]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/4
[silence]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/5
[lucky_worker]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/6
[merge_names]: http://discourse.stonehearth.net/t/rp-and-repeatpans-mods/4809/7
