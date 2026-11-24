# cross-cc

Scripts for building various cross compilers

## Supported Targets:
- x86_64-pc-freebsd15.1
- aarch64-unknown-freebsd15.1

## Requirements

- bash
- wget
- GNU autotools
- GNU make
- gcc

## Usage

```bash
./setup.sh
./setup.sh <target>

# Prints help
./setup.sh -h
./setup.sh --help

# List all targets
./setup.sh -l 
./setup.sh --list-targets
```