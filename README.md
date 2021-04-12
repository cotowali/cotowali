# Cotowari

A script language that transpile into POSIX sh

## Requirements

- [The V Programming Language](https://github.com/vlang/v)
    ```
    git clone https://github.com/vlang/v
    cd v
    make
    ```
- [zakuro9715/z](https://github.com/zakuro9715/z)
    ```
    go install github.com/zakuro9715/z
    # or
    curl -sSL gobinaries.com/zakuro9715/z | sh
    ```


## Installation

```
z build
sudo z symlink
```

## How to use

```
# compile
ri examples/add.ri
# execution
ri examples/add.ri | sh
```

## Development

### Directories

- `/cmd/ri` CLI entrypoint
- `/examples` Examples that can be compiled
- `/tests` Integration tests
- `/cotowari` Compiler code
