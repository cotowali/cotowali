<div align="center">
  <img width="200" src="https://raw.githubusercontent.com/cotowali/logo/main/cotowali.svg?sanitize=true">
  <h1>Cotowali</h1>
  <p>A statically typed script language that transpile into POSIX sh</p>
</div>

> This project is a prototyping stage right now.
> It means that only a few small snippets in `tests` will work.
> First release is planned for later this year.

## Concepts of Cotowali

- Outputs shell script that is fully compliant with POSIX standards.
- Simple syntax.
- Simple static type system.
- Syntax for shell specific feature like pipe and redirection.

## Example

```
fn fib(n int) int {
  if n < 2 {
    return n
  }
  return fib(n - 1) + fib(n - 2)
}

fn int | twice() int {
   let n = 0
   read(&n)
   return n * 2
}

assert fib(6) == 8
assert (fib(6) | twice()) == 16
```

[There is more examples](./examples)

## Installation

### Use binary

TODO

### Build from source

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
lic examples/add.li

# execution
lic examples/add.li | sh
# or
lic run examples/add.li
```

## Development

See [docs/development.md](./docs/development.md)

### Docker

```
docker compose run dev
```

## Acknowledgements

Cotowali is supported by 2021 Exploratory IT Human Resources Project ([The MITOU Program](https://www.ipa.go.jp/english/humandev/third.html) by IPA: Information-technology Promotion Agency, Japan.
