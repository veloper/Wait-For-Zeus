# Wait For Zeus
Starts the Zeus gem in the background and waits (blocks) until all of its sub-processes have loaded.

## Usage
When the script is first called within a Rails project it will call `zeus start` in a background job and redirect all output to the `$HOME/zeus.meta/ttysXXX/output.log` file. After all of the sub processes have been loaded the last output of Zeus will be `echo`ed to `STDOUT`. 

These actions and events are shown below...

```bash
$ ./wait_for_zeus.sh 
[PID: 32134] - Starting Zeus in background.
Loading Zeus Processes .............................
[PID: 32134] - Zeus is now running.
[ready] [crashed] [running] [connecting] [waiting]
boot
└── default_bundle
 ├── test_environment
 │  └── test_helper
 └── development_environment
  └── prerake

Available Commands: [waiting] [crashed] [ready]
zeus test (alias: rspec, testrb)
zeus console (alias: c)
zeus runner (alias: r)
zeus destroy (alias: d)
zeus dbconsole
zeus server (alias: s)
zeus generate (alias: g)
zeus rake

$ _
```

Running the script when an instance of Zeus exists within the current `tty` should prompt the user for actions...
```bash
$ ./wait_for_zeus.sh 
[PID: 32134] - Zeus is already running.
[ready] [crashed] [running] [connecting] [waiting]
boot
└── default_bundle
 ├── test_environment
 │  └── test_helper
 └── development_environment
  └── prerake

Available Commands: [waiting] [crashed] [ready]
zeus test (alias: rspec, testrb)
zeus console (alias: c)
zeus runner (alias: r)
zeus destroy (alias: d)
zeus dbconsole
zeus server (alias: s)
zeus generate (alias: g)
zeus rake

ACTIONS: [R]estart Zeus, [K]ill Zeus, [c]ontinue? [RKc]: _
```

## Warnings & Limitations
* The script was developed over a weekend and is largely untested.
* All process parsing is scoped through the current `tty`, which should be fine so long as each app has a seperate terminal tab.
    * **However**, the script will not operate as expected if one decides to switch between Rails projects (within the same tab/session) and calls `./wait_for_zeus.sh` multiple times.

## Author
* [Daniel Doezema](http://dan.doezema.com)

## Licence & Copyright
* New BSD License
* Copyright (c) 1999 - 2013, Daniel Doezema
