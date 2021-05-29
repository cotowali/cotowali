# Cotowari

A statically typed script language that transpile into POSIX sh

## Installation

See [installation.md](docs/installation.md)

## How to use

```
# compile
ric examples/add.ri

# execution
ric examples/add.ri | sh
# or
ric run examples/add.ri
```

## Example

```
fn fib(n int) int {
  if n < 2 {
    return n
  }
  return fib(n - 1) + fib(n - 2)
}

fib(7) # 13
```

[There is more examples](./examples)

## Development

See [docs/development.md](./docs/development.md)

### Docker

```
docker compose run dev
```
