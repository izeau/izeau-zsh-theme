# vim:et sts=2 sw=2 ft=zsh
#
# Eriner's Theme - fork of agnoster
# A Powerline-inspired theme for ZSH
#
# In order for this theme to render correctly, a font with Powerline symbols is
# required. A simple way to install a font with Powerline symbols is to follow
# the instructions here: https://github.com/powerline/fonts#installation
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.
#
# Requires the `git-info` zmodule to be included in the .zimrc file.

prompt_izeau_help () {
  cat <<EOH
This prompt is color-scheme-able. You can customize it using:

    prompt izeau [status_color] [pwd_color] [git_clean_color] [git_dirty_color]

where the parameters are the background colors for each segment. The default
values are black, cyan, green, and yellow.

In order for this prompt to render correctly, a font with Powerline symbols is
required. A simple way to install a font with Powerline symbols is to follow
the instructions here: https://github.com/powerline/fonts#installation
EOH
}

prompt_izeau_main() {
  local prompt_izeau_retval=${?}
  local prompt_izeau_color1=${1:-red}
  local prompt_izeau_color2=${2:-cyan}
  local prompt_izeau_color3=${3:-blue}

  ### Segment drawing
  # Utility functions to make it easy and re-usable to draw segmented prompts.

  local prompt_izeau_bg

  # Begin a segment. Takes two arguments, background color and contents of the
  # new segment.
  prompt_izeau_segment() {
    print -n "%K{${1}}"
    [[ -n ${prompt_izeau_bg} ]] && print -n "%F{${prompt_izeau_bg}}"
    print -n "${2}"
    prompt_izeau_bg=${1}
  }

  prompt_izeau_standout_segment() {
    print -n "%S%F{${1}}"
    [[ -n ${prompt_izeau_bg} ]] && print -n "%K{${prompt_izeau_bg}}%k"
    print -n "${2}%s"
    prompt_izeau_bg=${1}
  }

  # End the prompt, closing last segment.
  prompt_izeau_end() {
    print -n "%k%F{${prompt_izeau_bg}}%f "
  }

  ### Prompt components
  # Each component will draw itself, or hide itself if no information needs to
  # be shown.

  # Status: Was there an error? Am I root? Are there background jobs? Ranger
  # spawned shell? Who and where am I (user@hostname)?
  prompt_izeau_status() {
    local segment=''
    (( prompt_izeau_retval )) && segment+=' %F{white}✘'
    (( UID == 0 )) && segment+=' %F{white}⌗'
    (( $(jobs -l | wc -l) )) && segment+=' %F{white}⚙︎'
    (( RANGER_LEVEL )) && segment+=' %F{white}r'
    if [[ ${USER} != ${DEFAULT_USER} || -n ${SSH_CLIENT} ]]; then
       segment+=' ${USER}@%m'
    fi
    if [[ -n ${segment} ]]; then
      prompt_izeau_segment ${prompt_izeau_color1} "${segment} "
    fi
  }

  # Pwd: current working directory.
  prompt_izeau_pwd() {
    local izeau_path="$(print -Pn '%~')"
    local izeau_truncated_path="$(print -Pn '.../%3/')"
    if [[ ${#izeau_path} -gt ${#izeau_truncated_path} ]]; then
      izeau_path="$izeau_truncated_path"
    fi
    if [[ ${izeau_path:0:1} = / ]]; then
      izeau_path="${izeau_path:1}"
    fi
    prompt_izeau_standout_segment ${prompt_izeau_color2} " ${izeau_path//\//  } "
  }

  # AWS: current profile
  prompt_izeau_aws() {
    if [[ -n ${AWS_PROFILE} && -n *.tf(#qN) ]]; then
      prompt_izeau_standout_segment ${prompt_izeau_color3} " ⑇ $AWS_PROFILE "
    fi
  }

  # Git: branch/detached head, dirty status.
  prompt_izeau_git() {
    if [[ -n ${git_info} ]]; then
      local indicator
      [[ ${git_info[color]} == yellow ]] && indicator='± '
      prompt_izeau_standout_segment ${git_info[color]} " \${(e)git_info[prompt]} ${indicator}"
    fi
  }

  prompt_izeau_status
  prompt_izeau_pwd
  prompt_izeau_aws
  prompt_izeau_git
  prompt_izeau_end
}

prompt_izeau_precmd() {
  (( ${+functions[git-info]} )) && git-info
}

prompt_izeau_setup() {
  autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_izeau_precmd

  prompt_opts=(cr percent sp subst)

  local prompt_izeau_color3=${3:-green}
  local prompt_izeau_color4=${4:-yellow}

  zstyle ':zim:git-info:branch' format ' %b'
  zstyle ':zim:git-info:commit' format '➦ %c'
  zstyle ':zim:git-info:action' format ' (%s)'
  zstyle ':zim:git-info:clean' format ${prompt_izeau_color3}
  zstyle ':zim:git-info:dirty' format ${prompt_izeau_color4}
  zstyle ':zim:git-info:keys' format \
    'prompt' '%b%c%s' \
    'color' '%C%D'

  PS1="\${(e)\$(prompt_izeau_main ${@:1:2})}"
  RPS1=''
}

prompt_izeau_preview () {
  if (( ${#} )); then
    prompt_preview_theme izeau "${@}"
  else
    prompt_preview_theme izeau
    print
    prompt_preview_theme izeau red cyan green yellow
  fi
}

prompt_izeau_setup "${@}"
