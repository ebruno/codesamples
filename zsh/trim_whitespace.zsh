remove_whitespace() {
    local var="$*"
    # Remove leading whitespace characters
    var="${var#${var%%[![:space:]]*}}"
    # Remove trailing whitespace characters
    var="${var%${var##*[![:space:]]}}"
    print -r -- "$var"
}
