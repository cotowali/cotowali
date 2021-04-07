# Cotowari

A script language that transpile into POSIX sh

## How to use

- setup V https://github.com/vlang/v
- `v -o ./ri cmd/ri`
- `./ri examples/add.ri | sh`

## Development

See z.yaml

### Directories

- `/cmd/ri` CLI entrypoint
- `/examples` Examples that can be compiled
- `/tests` Integration tests
- `/cotowari` Compiler code
