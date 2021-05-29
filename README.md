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

## Development

See [docs/development.md](./docs/development.md)

### Docker

```
docker compose run dev
```
