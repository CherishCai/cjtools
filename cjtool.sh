#!/bin/bash

set -e

DATE=$(date "+%Y%m%d%H%M%S")
SLEEP_TIME=1

choice=''
PID=''
PJ=''
TP=''
FREE=''

JSTACK_LOG="/tmp/jstack-${PID}-${DATE}.jstack"

psjava(){
    PJ=`ps axu | grep -v grep | grep java`
    echo -e "\n>>> ps axu | grep -v grep | grep java"
    echo -e "$PJ"

    if [[ "x" == "x$PJ" ]];then
        echo "has no jvm process, so exit"
        exit -1
    fi
}

topPid(){
    TP_LOG=top_Hp-${PID}-${DATE}.log
    TP=`top -n 1 -Hp $PID`
    echo -e "\n>>> top -Hp $PID"
    echo -e "$TP"
    echo -e "Write (top -Hp $PID) msg into $TP_LOG\n"
    echo -e "$TP" > $TP_LOG
}

jstackPid(){
    JSTACK_LOG=jstack-${PID}-${DATE}.jstack
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Begin to process jstack. write into $JSTACK_LOG"

    jstack -l $PID > $JSTACK_LOG
    if [[ $? != 0 ]]; then
        echo -e "\033[31mprocess jstack error.\033[0m"
    fi

    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Finish to process jstack.\n"
    sleep ${SLEEP_TIME}
}

freeCmd(){
    FREE_LOG=free_m-${PID}-${DATE}.log
    FREE=`free -m`
    echo ""
    echo ">>> free -m"
    echo -e "$FREE"
    echo -e "Write (free -m) msg into $FREE_LOG\n"
    echo -e "$FREE" > $FREE_LOG
}

jinfoFlags(){
    # jinfo -flags $PID
    JINFO_FLAGS_LOG=jinfo_flags-${PID}-${DATE}.log
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') Begin to process jinfo -flags. write into $JINFO_FLAGS_LOG"
    jinfo -flags $PID 1>${JINFO_FLAGS_LOG} 2>&1
    if [[ $? != 0 ]]; then
      echo -e "\033[31mprocess jinfo -flags error.\033[0m"
    fi
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Finish to process jinfo -flags."
}

jmapHeap(){
    #jmap -heap
    JMAP_HEAP_LOG=jmap_heap-${PID}-${DATE}.log
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') Begin to process jmap -heap. write into $JMAP_HEAP_LOG"
    
    jmap -heap $PID > ${JMAP_HEAP_LOG}
    if [[ $? != 0 ]]; then
      echo -e "\033[31mprocess jmap -heap error.\033[0m"
    fi
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Finish to process jmap -heap."
}

jmapHisto(){
    # jmap -histo
    JMAP_HISTO_LOG=jmap_histo-${PID}-${DATE}.log
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Begin to process jmap -histo. write into $JMAP_HISTO_LOG"
    
    jmap -histo $PID > ${JMAP_HISTO_LOG}
    if [[ $? != 0 ]]; then
        echo -e "\033[31mprocess jmap -histo error.\033[0m"
    fi
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') Finish to process jmap -histo.\n"
    sleep ${SLEEP_TIME}
}

needFullGC(){
    echo ""
    echo -e "\033[31mBelow cmd need full GC, do it if you need!\033[0m"

    JMAP_HISTO_LIVE_LOG=jmap_histo_live-${PID}-${DATE}.log
    echo "jmap -histo:live $PID > ${JMAP_HISTO_LIVE_LOG}"

    JMAP_DUMP_FILE=jmap_dump_live-${PID}-${DATE}.bin
    echo "jmap -dump:live,format=b,file=${JMAP_DUMP_FILE} $PID"
}

suggest(){
    echo ""
    echo " suggest maybe !"
    echo ""
}

pidAndChoice(){
    while [[ "x" == "x$PID" ]]; do
        # do ps java
        psjava
        read -p "Please enter PID:" PID
    done

    echo ""
    echo "1. CPU"
    echo "2. Memory"
    echo "8. Suggest"
    echo "9. ALL"
    read -p "Please enter your choice (default 9):" choice 
    
    if [[ "x" == "x$choice" ]]; then
        choice='9'
    fi
}

main(){

    pidAndChoice

    echo ""
    echo "PID:$PID"
    echo "choice:$choice"

    if [ 9 -eq $choice -o 8 -eq $choice ]; then
        suggest
    fi

    if [ 9 -eq $choice -o 8 -ne $choice ]; then
        # ne suggest
        jinfoFlags
    fi

    if [ 9 -eq $choice -o 1 -eq $choice ]; then
        topPid
        jstackPid
    fi

    if [ 9 -eq $choice -o 2 -eq $choice ]; then
        freeCmd

        needFullGC
        
        jmapHisto
        jmapHeap

        needFullGC
    fi

    echo ""
    echo "End cjvmtools.sh"
}

main
