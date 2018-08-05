#!/bin/bash

LOGDIR="/root/nouser_logs"

[ ! -d $LOGDIR ] && mkdir $LOGDIR

curlog="$LOGDIR/nouser_$( date +%Y%m%d ).log"
find / -nouser -print > $curlog
mail -s "Files without ownership for $( date )" root < $curlog
