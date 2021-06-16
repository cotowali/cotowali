<div align="center">
  <img width="200" src="https://raw.githubusercontent.com/cotowari/logo/main/cotowari.svg?sanitize=true">
  <h1>Cotowari</h1>
  <p>A statically typed script language that transpile into POSIX sh</p>
</div>

> This project is a prototyping stage right now.
> It means that only a few small snippets in `tests` will work.
> First release is planned for later this year.

## Concepts of Cotowari

- Outputs shell script that is fully compliant with POSIX standards.
- Simple syntax.
- Simple statically type system.
- Syntax for shell specific feature like pipe and redirection.

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

fn int | twice() int {
   let n = read()
   return n * 2
}

assert fib(6) == 8
assert (fib(6) | twice()) == 16
```

[There is more examples](./examples)

## Development

See [docs/development.md](./docs/development.md)

### Docker

```
docker compose run dev
```

