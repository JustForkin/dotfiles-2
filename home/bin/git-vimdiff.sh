#!/bin/sh
# Use vimdiff to quickly go through Git merge conflicts.
#
# Save your changes to the LOCAL file. MERGED will be updated if
# vimdiff exits cleanly. Use :cq to abort.
#
# Put the following in your ~/.gitconfig
#
# [mergetool "vimdiffconflicts"]
#     cmd = unmerge.sh $BASE $LOCAL $REMOTE $MERGED
#     trustExitCode = true

if [[ -z $@ || $# != "4" ]] ; then
    echo -e "Usage: $0 \$BASE \$LOCAL \$REMOTE \$MERGED"
    exit 1
fi

BASE="$1"
LOCAL="$2"
REMOTE="$3"
MERGED="$4"

# sed -e '/<<<<<<</,/=======/d' -e '/>>>>>>>/d' $MERGED > $LOCAL
# sed -e '/=======/,/>>>>>>>/d' -e '/<<<<<<</d' $MERGED > $REMOTE

VIMDIFFCMD="nvim -d"
if [ -f "$BASE" ]; then
    # $VIMDIFFCMD -f "$LOCAL" "$BASE" "$REMOTE"
    $VIMDIFFCMD -f "$LOCAL" "$REMOTE"
else
    $VIMDIFFCMD -f "$LOCAL" "$REMOTE"
fi

EC=$?

# Overwrite $MERGED
[[ $EC == "0" ]] && cat "$LOCAL" > "$MERGED"

exit $EC
