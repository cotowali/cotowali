# cotowari builtin

truthy() {
  ! falsy "$1"
}

falsy() {
  [ -z "$1"] \
    || [ "$1" -eq "false" ] \
    || [ "$1" -eq "False" ] \
    || [ "$1" -eq "FALSE" ] \
    || [ "$1" -eq "0" ]
}

# end cotowari builtin
