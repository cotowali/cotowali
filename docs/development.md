# Docs for developpers

## Directories

- `/cmd/ri` CLI entrypoint
- `/examples` Examples that can be compiled
- `/tests` Integration tests
- `/cotowari` Compiler code


## Integration Test

See `z test integration --help`

### Success Test

Check exit status is 0 and output.

`tests/testname.ri`: source code
`tests/testname.out`: output

### Error Test

Check exit status is not 0 and error output

If filename has suffix, `_err.ri`, it is error test.

`tests/testname_err.ri`: source code
`tests/testname_err.out`: error output

### Fix mode

`z test fix` will be update output automatically. You should check that updated output is correct before commit it.
