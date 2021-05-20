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

Check exit status is 0 and output.

`tests/testname.ri`: source code
`tests/testname.out`: output

#### Error Test

Check exit status is not 0 and error output

If filename has suffix, `_err.ri`, it is error test.

`tests/testname_err.ri`: source code
`tests/testname_err.out`: error output

#### TODO Test

If filename has suffix `.todo.ri`, it is todo test. todo test will be executed but it does not checked.
If output matches with `.todo.out`, `.todo` will be removed by using fix mode.

### Fix mode

`z test fix` will be update output automatically. You should check that updated output is correct before commit it.
