# cotowari builtin

truthy() {
  ! falsy "$1"
}

falsy() {
  [ -z "$1" ] \
    || [ "$1" = "false" ] \
    || [ "$1" = "False" ] \
    || [ "$1" = "FALSE" ] \
    || [ "$1" = "0" ]
}

# end cotowari builtin
