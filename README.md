<div align="center">
  <img width="200" src="https://raw.githubusercontent.com/cotowali/design/main/assets/cotowali.svg?sanitize=true">
  <h1>Cotowali</h1>
  <p>A statically typed scripting language that transpile into POSIX sh</p>
  <a href="http://mozilla.org/MPL/2.0/" rel="nofollow">
    <img  alt="License: MPL 2.0" src="https://img.shields.io/badge/License-MPL%202.0-blue.svg?style=flat-square">
  </a>
</div>

> This project is Work in Progress. First release is planned for later 2021.

## Concepts of Cotowali

- Outputs shell script that is fully compliant with POSIX standards.
- Simple syntax.
- Simple static type system.
- Syntax for shell specific feature like pipe and redirection.

## Example

```
fn fib(n: int) int {
  if n < 2 {
    return n
  }
  return fib(n - 1) + fib(n - 2)
}

fn int |> twice() int {
   var n = 0
   read(&n)
   return n * 2
}

assert(fib(6) == 8)
assert((fib(6) |> twice()) == 16)

fn ...int |> sum() int {
  var v: int
  var res = 0
  while read(&v) {
    res += v
  }
  return res
}

fn ...int |> twice_each() |> ...int {
  var n: int
  while read(&n) {
    yield n * 2
  }
}

assert((seq(3) |> sum()) == 6)
assert((seq(3) |> twice_each() |> sum()) == 12)

// Call command by `@command` syntax with pipeline operator
assert(((1, 2) |> @awk('{print $1 + $2}')) == '3')
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

## Author

zakuro &lt;z@kuro.red&gt;

## Acknowledgements

Cotowali is supported by 2021 Exploratory IT Human Resources Project ([The MITOU Program](https://www.ipa.go.jp/english/humandev/third.html) by IPA: Information-technology Promotion Agency, Japan.
