# Adapted from https://github.com/Delapouite/kakoune-buffers

declare-option str-list quick_buffers

declare-user-mode quick-buffers

map global quick-buffers a ':set-option -add global quick_buffers %val{bufname}<ret>' -docstring 'add buffer to quick buffers list'
map global quick-buffers r ':set-option -remove global quick_buffers %val{bufname}<ret>' -docstring 'remove buffer from quick buffers list'
map global quick-buffers e ':quick-buffers-edit<ret>' -docstring 'edit current quick buffers list'
map global quick-buffers s ':quick-buffers-show<ret>' -docstring 'show current quick buffers list'

define-command -params 1 quick-buffers-at-index %{
  evaluate-commands %sh{
    target=$1
    i=0
    eval "set -- $kak_quoted_opt_quick_buffers"
    while [ "$1" ]; do
      i=$((i+1))
      if [ $i = $target ]; then
        printf "buffer '$1'"
        exit
      fi
      shift
    done
  }
}

define-command -docstring 'shows the current buffers added to the quick list' quick-buffers-show %{
  evaluate-commands %sh{
    printf "info -title 'Quick buffers' -- %%^"
    i=0
    eval "set -- $kak_quoted_opt_quick_buffers"
    while [ "$1" ]; do
      i=$((i+1))
      bufferName=$1
      printf "%02d: $bufferName\n" "$i"
      shift
    done
    printf "^\n"
  }
}

define-command -docstring 'opens a buffer where the quick buffer list can be edited' quick-buffers-edit %{
  evaluate-commands %{
    evaluate-commands %sh{
      output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-quick-buffers.XXXXXXXX)/fifo
      mkfifo ${output}

      eval "set -- $kak_quoted_opt_quick_buffers"
      bufferName=""
      while [ "$1" ]; do
        bufferName="${bufferName}${1}\n"
        shift
      done
      ( printf "$bufferName" > ${output} 2>&1 & ) > /dev/null 2>&1 < /dev/null
      printf "%s" "evaluate-commands %{
        edit! -fifo ${output} *quick_buffer_edit*
        hook -once buffer BufClose .* %{
          execute-keys '%<a-s>_'
          set-option global quick_buffers %val{selections}
        }
        hook -once buffer BufCloseFifo .* %{
          nop %sh{ rm -r $(dirname ${output}) }
        }
      }"
    }
  }
}
