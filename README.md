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

See [docs/development.md](./docs/development.md)

### Docker

```
docker compose run dev
```
