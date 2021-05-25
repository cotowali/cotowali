# Docs for developpers

## Directories

- `/cmd/ri` CLI entrypoint
- `/examples` Examples that can be compiled
- `/tests` Integration tests
- `/cotowari` Compiler code

## Testing

### Run

- `z test`: run all tests
- `z test test.ri|some_test.v`: run specified test. Test runner is automaticaly selected
- `z test unit`: run all unit tests
- `z test integration`: run all integration tests

### Integration Test

See `z test integration --help`

#### Success Test

`xxx.ri`

- It can be compiled with no error.
- It runs successfully (exit with zero).
- output matches `xxx.out`.

#### Error Test

`xxx_err.ri` or `error.ri`

- It fail to compile (compiler exit with non-zero status).
- Compiler output matches `xxx_err.out` or `error.out`

#### TODO Test

`xxx.todo.ri` or `xxx_err.todo.ri`

If output matches with `.todo.out`, `.todo` will be removed by using fix mode.

#### Fix mode

`z test fix` will be update output automatically. You should check that updated output is correct before commit it.
