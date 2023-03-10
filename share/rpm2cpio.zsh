#!/usr/bin/env zsh
#
# -*- mode: sh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
#
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors
# Copyright (c) 2021-2022 zdharma-continuum and contributors

emulate -R zsh -o extendedglob

local pkg=$1
if [[ -z $pkg || ! -e $pkg ]]; then
  print -u2 -Pr "%F{160}rpm2cpio.sh%f: no package supplied"
  exit 1
fi

local leadsize=96
local o=$(( $leadsize + 8 ))
set -- ${(s: :)$(od -j $o -N 8 -t u1 $pkg)}
local i=$(( 256 * ( 256 * ( 256 * $2 + $3 ) + $4 ) + $5 ))
local d=$(( 256 * ( 256 * ( 256 * $6 + $7 ) + $8 ) + $9 ))

sigsize=$(( 8 + 16 * $i + $d ))
o=$(( $o + $sigsize + ( 8 - ( $sigsize % 8 ) ) % 8 + 8 ))
set -- ${(s: :)$(od -j $o -N 8 -t u1 $pkg)}
i=$(( 256 * ( 256 * ( 256 * $2 + $3 ) + $4 ) + $5 ))
d=$(( 256 * ( 256 * ( 256 * $6 + $7 ) + $8 ) + $9 ))

local hdrsize=$(( 8 + 16 * $i + $d ))
o=$(( $o + $hdrsize ))
local -a UNPACKCMD
UNPACKCMD=( dd if=$pkg ibs=$o skip=1 )

local COMPRESSION="$($=UNPACKCMD | file -)"
local -a DECOMPRESSCMD

if [[ $COMPRESSION == (#i)*gzip* ]]; then
  DECOMPRESSCMD=( gunzip )
elif [[ $COMPRESSION == (#i)*bzip2* ]]; then
  DECOMPRESSCMD=( bunzip2 )
elif [[ $COMPRESSION == (#i)*xz* ]]; then
  DECOMPRESSCMD=( unxz )
elif [[ $COMPRESSION == (#i)*cpio* ]]; then
  DECOMPRESSCMD=( cat )
else
  DECOMPRESSCMD=( $(which unlzma 2>/dev/null) )
  if [[ $DECOMPRESSCMD != /* ]]; then
    DECOMPRESSCMD=( $(which lzmash 2>/dev/null) )
    if [[ $DECOMPRESSCMD == /* ]]; then
      DECOMPRESSCMD=( lzmash -d -c )
    else
      DECOMPRESSCMD=( cat )
    fi
  fi
fi

command "$UNPACKCMD[@]" 2>/dev/null | command "$DECOMPRESSCMD[@]"

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
