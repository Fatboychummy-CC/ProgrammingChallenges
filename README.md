# Programming Challenges
This repository contains my solutions to various programming challenges from
different sources, as well as an actual challenge runner that can be used to
run and test your own solutions.

The runner is also capable of getting the challenge descriptions (and test
data), as well as submitting your solutions to the challenge websites.

## Features
- Encrypted credential storage for challenge websites.
- Automatic test running and output comparison.
- Interactive mode to test your solutions.
- Extensible to support more challenge websites.
- Libraries folder that is exposed to all challenge scripts for ease of use.

## Supported Challenge Websites
Currently only Advent of Code is supported, but I plan to add more in the
future.

Plans for the future include:
- [ ] Kattis
- [ ] LeetCode
- [ ] Others, if they're brought to my attention and support Lua.

## Usage

### Getting Started
To get started, you can use the installer on CraftOS-PC by running the following
command:
```shell
wget run i-have-not-built-an-installer-yet-lol
```

This will install the challenge runner and all of its dependencies.

### Getting/Running/Submitting Challenges
Once installed, you can get help information by just running the `challenge`
command (or `challenge help`):
```shell
challenge
```

For all of getting, running, and submitting challenges, each challenge site can
define their own amount of arguments required, but they will all use the base
`challenge sitename <get|update|submit|run|interactive> ...` structure. As an
example, Advent of Code requires the year, day, and part as arguments for most
commands:
```shell
# Download the first part of the third day of 2024
challenge advent-of-code get 2024 3 1
```

Challenges are downloaded to the `challenges/site-name` folder, and each
individual challenge has the following files:
- `description.md`: The description of the challenge.
- `name.txt`: The name of the challenge.
- `tests/`: A folder containing the various test data for the challenge.
  - `inputs/`: Contains the input data for each test, named `#.txt`.
  - `output/`: Contains the expected output for each test, named `#.txt`.
- `input.txt`: The input data for the challenge.
- `run.lua`: The Lua script that you should provide your solution in.
- `output.txt`: Not created until the challenge is ran at least once, contains
  the last output of the challenge.

The individual challenge libraries define their own save structure, but as a
general rule, the challenges will be downloaded such that each argument passed
to the `get` command will be a subfolder "deeper". Again, using the earlier
Advent of Code example, the challenge would be saved to
`challenges/advent-of-code/2024/3/1/`.

### Extending the Runner
If you want to add support for a new challenge website, you can do so by
creating a new lua file in the `challenge_sites` folder. Copy the format of the
`example.lua` file you can find there (not downloaded normally by the
installer!), and it will automatically be registered as a new challenge site.