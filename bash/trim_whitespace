#  Remove leading and trailing whitespace.
#  The code is bit dense so hopefully the following will
#  make the code more understandable. The text is taken from
#  the bash documentation.
#
#  The (colon) : indicates to do nothing except
#  expanding arguments and performing redirections.
#
# (underscore)  _   At shell startup, set to the pathname used to invoke
#                   the shell or shell script being executed as passed in
#                   the environment or argument list. Subsequently,
#                   expands to the last argument to the previous
#                   simple command executed in the foreground,
#                   after expansion. It is also set to the full pathname used
#                   to invoke each command executed and placed in the
#                   environment exported to that command. When checking mail,
#                   this parameter holds the name of the mail file.
#  $_  Last field of the the last command.
#  It is assume that only one parameter is passed.

remove_whitespace() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf "%s" "$_"
}
