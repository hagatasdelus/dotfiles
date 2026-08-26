# PATH configuration for fish

set -l arch (uname -m)
if test "$arch" = "arm64"; and test -f /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test "$arch" = "x86_64"; and test -f /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

# Collect directories that exist, in priority order
set -l extra_path
for dir in \
    $HOME/scripts \
    $HOME/.local/bin \
    $HOME/.scripts \
    $HOME/.scripts/bin \
    $HOME/go/bin \
    $HOME/.cargo/bin \
    $HOME/.poetry/bin \
    $HOME/.bun/bin \
    $HOME/.deno/bin \
    $HOME/.local/share/mise/shims \
    /Applications/Xcode.app/Contents/Developer/usr/bin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    /usr/local/bin \
    /usr/local/sbin \
    /opt/local/sbin \
    /usr/bin \
    /bin \
    /usr/sbin \
    /sbin \
    $HOME/bin \
    /opt/subversion/bin \
    /usr/local/ant/bin \
    /usr/local/checker/bin

    test -d $dir; and set -a extra_path $dir
end

# Add paths to fish PATH
if test (count $extra_path) -gt 0
    fish_add_path --path -gp $extra_path
end

# PNPM PATH
if test -d "$HOME/.local/share/pnpm"
    fish_add_path --path -gp "$HOME/.local/share/pnpm"
end
