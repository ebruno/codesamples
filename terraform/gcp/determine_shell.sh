if [ ! -n "${ZSH_VERSION}" ]; then
    if [ ! -n "${BASH_VERSION}" ]; then
	CURSHELL="sh";
    else
	if [ "$(basename "$0")" == "sh" ]; then
	    CURSHELL="sh";
	else
	    CURSHELL="bash";
	    fi;
    fi;
else
    CURSHELL="zsh";
fi;
echo "${CURSHELL}";
