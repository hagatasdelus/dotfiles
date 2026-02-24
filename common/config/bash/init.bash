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

# pip
if type pip &>/dev/null; then
    function cache::pip() {
        pip completion --bash > ${CACHE_PROFILE}/pip.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/pip.bash ]]; then
        cache::pip
    fi
    . ${CACHE_PROFILE}/pip.bash
fi
if type pip2 &>/dev/null; then
    function cache::pip2() {
        pip2 completion --bash > ${CACHE_PROFILE}/pip2.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/pip2.bash ]]; then
        cache::pip2
    fi
    . ${CACHE_PROFILE}/pip2.bash
fi
if type pip3 &>/dev/null; then
    function cache::pip3() {
        pip3 completion --bash > ${CACHE_PROFILE}/pip3.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/pip3.bash ]]; then
        cache::pip3
    fi
    . ${CACHE_PROFILE}/pip3.bash
fi

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

# pnpm
if [[ -d "${HOME}/.local/share/pnpm" ]]; then
    export PNPM_HOME="${HOME}/.local/share/pnpm"
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

# Docker
if [[ -d /Applications/Docker.app ]]; then
    alias docker=/Applications/Docker.app/Contents/Resources/bin/docker
fi
if type docker &>/dev/null; then
    function cache::docker() {
        docker completion bash > ${CACHE_PROFILE}/docker.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/docker.bash ]]; then
        cache::docker
    fi
    . ${CACHE_PROFILE}/docker.bash
fi

# kubectl
if type kubectl &>/dev/null; then
    function cache::kubectl() {
        kubectl completion bash > ${CACHE_PROFILE}/kubectl.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/kubectl.bash ]]; then
        cache::kubectl
    fi
    . ${CACHE_PROFILE}/kubectl.bash
fi

# Deno
if type deno &>/dev/null; then
    function cache::deno() {
        deno completions bash > ${CACHE_PROFILE}/deno.bash
    }
    if [[ ! -f ${CACHE_PROFILE}/deno.bash ]]; then
        cache::deno
    fi
    . ${CACHE_PROFILE}/deno.bash
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
