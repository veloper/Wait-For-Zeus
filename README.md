# Wait For Zeus
Starts the Zeus gem in the background and waits (blocks) until all of its sub-processes have loaded.

## Usage
This script can be simply called like so

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

$
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

ACTIONS: [R]estart Zeus, [K]ill Zeus, [c]ontinue? [RKc]: 

```

## Author
* Daniel Doezema

## Licence & Copyright
* New BSD License
* Copyright (c) 1999 - 2013, Daniel Doezema
