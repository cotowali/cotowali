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
#
# stderr:
# 0
# ---
echo('---')
echo('exit')
echo('0') 1>&2
```
