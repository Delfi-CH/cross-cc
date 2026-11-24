# cross-cc

Scripts for building various cross compilers

## Basic Usage

```bash
./install.sh -t <Target>
./uninstall.sh -t <Target>
```

For more info run `./install.sh -h`

## Supported Targets:
- x86_64-pc-freebsd15.1
- aarch64-unknown-freebsd15.1

## Requirements

- bash
- wget
- GNU autotools
- GNU make
- gcc
- python3
- GNU getopt