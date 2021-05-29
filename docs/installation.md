# Cotowari Install Guide

## Use binary

TODO

## Build from source

0. Install required tools

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

1. Build

    ```
    z build
    ```

2. Install

    ```
    sudo z symlink
    # or
    sudo z install
    ```

## How to use

```
# compile
ric examples/add.ri

# execution
ric examples/add.ri | sh
# or
ric run examples/add.ri
```
