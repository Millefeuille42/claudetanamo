# claudetanamo
Secure claude container sandbox for macOS using Apple containers

Uses Apple container for reinforced isolation, also prenvents the containerfrom accessing any local network using pf.

It also forwards your git commiter id and claude's state persists in between runs (state is unique per project).

Claude will default to plan mode.

## Run

The container runs with the same UID and GUID as the current user.

Run `bin/setup.sh` to setup the sandbox, this will start the container runtime, create the container image, and setup the pf rules.

Link or copy the `bin/claudetanamo` file into your `PATH`.

Once done run `claudetanamo` in your project directory, you will be prompted to log in if the API KEY is not provided or if the oauth token is not available.

It is possible change from plan mode to RW modes, either when running claude interactively (without any arguments) 
or by providing any of those two flags `--permission-mode <mode>` or `--dangerously-skip-permissions`.

It is possible to provide the container with runtime-installed packages with the `.claudetanamo/tools.nix` file, some pre-made templates for specific languages were made as well as 
a generic demo one.
