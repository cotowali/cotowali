## test file format

```
# meta data
# ---

source code
```

example:

```
# exit: 0
# stdout:
# a
#   b
#   c
# ---

echo('a')
echo('  b')
echo('  c')
```

```
# stdout: << end
# ---
# exit
# end
# ---
echo('---')
echo('exit')
```
