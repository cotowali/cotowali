Before first release
====================

monthly.2021.11
---------------

- glob literal `@'*.txt'`
- pipe input as parameter `fn (pipe_in: int) |> f()`
- operator overload
    - prefix `fn -(v: Type): Type`
    - infix `fn (lhs: Type) + (rhs: Type): Type`
    - cast `fn (v: Type) as(): ToType`
- compiler directive (coditinoal compilation)
- break / continue
- require now search file in COTOWALI_PATH
- builtin test runner
    - `lic test` command
    - `#[test]` attribute

monthly.2021.11
---------------

- support `require 'http:...'` and `require 'github:...'`
- Supports checksum verification in `require`
- `#error` and `#warning` compiler directive
- integrated inline shell
- support macOS
- change function syntax to require `:` before return type
- bug fixes

monthly.2021.10
---------------

- lish (Cotowali interactive shell)
- document comment `/// comment`
- pow operator `**`
- index access for string
- disallow use of variadic in element of tuple `(...int)`
- disallow nested tuple
- tuple type expansion `(...(int, int), ...(int, int))`
- tuple expansion `(...(0, 1), ...(2, 3))`
- equality operator `==`, `!=` for tuple
- nested function
- disallow assignment to variable outside of function
- namespace
- redirection `"hello" |> "hello.txt"` `"hello" |>> "hello.txt"`
- discard variable `var _ = f()`
- function variable
- method

monthly.2021.09
---------------

- float literal in E notation
- string siteral
    - escape sequence
    - raw string
    - variable substitution
    - expr substitution
- [destructuring assignment](https://github.com/cotowali/cotowali/blob/4b986ff95b90ce1fbbd2ea0b76480261b2058303/tests/assign_test.li#L35-L44)
- attribute syntax
- Type alias

monthly.2021.08
---------------

- Syntax
    - variables
    - functions
    - pipeline
    - if statement
    - for statement
    - while statement
    - assert statement
    - etc...
- Builtin Types
    - int
    - float
    - bool
    - string
    - map
    - array
