# cross-cc

Scripts for building various cross compilers

## Basic Usage

```bash
./install.sh -t <Target>
./uninstall.sh -t <Target>
```

For more info run `./install.sh -h`

## Supported Targets:
- x86_64-unknown-freebsd15.1
- aarch64-unknown-freebsd15.1
- x86_64-unknown-netbsd
- i686-unknown-netbsdelf

## Requirements

- bash
- wget
- GNU autotools
- GNU make
- gcc
- python3
- GNU getopt