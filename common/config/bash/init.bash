export LANGUAGE="en_US:en"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PLATFORM="$(uname)"

export CACHE_PROFILE="${XDG_CACHE_HOME}/bash/profile"
mkdir -p ${CACHE_PROFILE}
function cache::clear() {
    rm -rf ${CACHE_PROFILE}
    mkdir -p ${CACHE_PROFILE}
}

### ls/eza ###
function ls() {
    if command -v eza >/dev/null 2>&1; then
        command eza -l --header --icons "$@"
    else
        command ls -lhAFG "$@"
    fi
}

### cd ###
function cd() {
    builtin cd "$@" && {
        if command -v eza >/dev/null 2>&1; then
            command eza -l --header --icons
        else
            command ls -lhAFG
        fi
    }
}

### Mise ###
if type mise &>/dev/null; then
    function cache::mise() {
        mise activate bash > ${CACHE_PROFILE}/mise.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/mise.bash ]]; then
        cache::mise
    fi
    . ${CACHE_PROFILE}/mise.bash
fi

### Starship ###
# if type starship &>/dev/null; then
#     function cache::starship() {
#         starship init bash > ${CACHE_PROFILE}/starship.bash
#     }
#     if [[ ! -f ${CACHE_PROFILE}/starship.bash ]]; then
#         cache::starship
#     fi
#     . ${CACHE_PROFILE}/starship.bash
# fi

### bexar ###
# if type bexar &>/dev/null; then
#     function cache::bexar() {
#         bexar init --bind > ${CACHE_PROFILE}/bexar.bash
#     }
#     if [[ ! -f ${CACHE_PROFILE}/bexar.bash ]]; then
#         cache::bexar
#     fi
#     . ${CACHE_PROFILE}/bexar.bash
# fi
