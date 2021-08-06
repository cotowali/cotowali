# Docs for developpers

## Development Philosophy

### Be readable code

**Be readable code is the most important**

- It's easy to spoil clean code, but hard to get it back.
- In any time, improving readability is justice.

### Performance

**Cotowali doesn't have to be fast.**

- Cotowali target small (~10k LoC) `.li` source code.
- Of course it's better to be fast. But it is not important.
- This doesn't mean the code has to be super slow.

## Testing

### Run

- `z test`: run all tests
- `z test test.li|some_test.v`: run specified test. Test runner is automaticaly selected
- `z test unit`: run all unit tests
- `z test integration`: run all integration tests

### Integration Test

See `z test integration --help`

#### Success Test

`xxx.li`

- It can be compiled with no error.
- It runs successfully (exit with zero).
- output matches `xxx.out`.

#### Error Test

`xxx_err.li` or `error.li`

- It fail to compile (compiler exit with non-zero status).
- Compiler output matches `xxx_err.out` or `error.out`

#### TODO Test

`xxx.todo.li` or `xxx_err.todo.li`

If output matches with `.todo.out`, `.todo` will be removed by using fix mode.

#### Fix mode

`z test --fix` will be update output automatically. You should check that updated output is correct before commit it.

#### Shellcheck Test (WIP)

shellcheck test requires [shellcheck](https://github.com/koalaman/shellcheck)

```
z test --shellcheck test.li
```
