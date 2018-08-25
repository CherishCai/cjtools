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
    echo -e "\n\033[34m>>> ps axu | grep -v 'grep' | egrep 'java|PID'\033[0m"
    ps axu | grep -v 'grep' | egrep 'java|PID'

    psjavacount=`ps axu | grep -v 'grep' | grep -c java`

    if [ 0 -eq $psjavacount ];then
        echo "has no jvm process, so exit"
        exit -1
    fi
    
    PJ=`ps axu | grep -v 'grep' | grep java`
    
    if [ 1 -eq $psjavacount ];then
        PID=`echo $PJ | cut -d ' ' -f 2`
    fi

}

topPid(){
    TP_LOG=top_Hp-${PID}-${DATE}.log
    TP=`top -n 1 -Hp $PID`
    echo -e "\n\033[34m>>> top -Hp $PID\033[0m"
    echo -e "$TP"
    echo -e "\033[34mWrite (top -Hp $PID) msg into $TP_LOG\033[0m\n"
    echo -e "$TP" > $TP_LOG
}

jstackPid(){
    JSTACK_LOG=jstack-${PID}-${DATE}.jstack
    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Begin to process jstack. write into $JSTACK_LOG\033[0m"

    jstack -l $PID > $JSTACK_LOG
    if [[ $? != 0 ]]; then
        echo -e "\033[31mprocess jstack error.\033[0m"
    fi

    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Finish to process jstack.\033[0m\n"
    sleep ${SLEEP_TIME}
}

freeCmd(){
    FREE_LOG=free_m-${PID}-${DATE}.log
    FREE=`free -m`
    echo ""
    echo -e "\033[34m>>> free -m\033[0m"
    echo -e "$FREE"
    echo -e "\033[34mWrite (free -m) msg into $FREE_LOG\033[0m\n"
    echo -e "$FREE" > $FREE_LOG
}

jinfoFlags(){
    # jinfo -flags $PID
    JINFO_FLAGS_LOG=jinfo_flags-${PID}-${DATE}.log
    echo -e "\n\033[34m$(date '+%Y-%m-%d %H:%M:%S') Begin to process jinfo -flags. write into $JINFO_FLAGS_LOG\033[0m"
    jinfo -flags $PID 1>${JINFO_FLAGS_LOG} 2>&1
    if [[ $? != 0 ]]; then
      echo -e "\033[31mprocess jinfo -flags error.\033[0m"
    fi
    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Finish to process jinfo -flags.\033[0m"
}

jmapHeap(){
    #jmap -heap
    JMAP_HEAP_LOG=jmap_heap-${PID}-${DATE}.log
    echo -e "\n\033[34m$(date '+%Y-%m-%d %H:%M:%S') Begin to process jmap -heap. write into $JMAP_HEAP_LOG\033[0m"
    
    jmap -heap $PID > ${JMAP_HEAP_LOG}
    if [[ $? != 0 ]]; then
      echo -e "\033[31mprocess jmap -heap error.\033[0m"
    fi
    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Finish to process jmap -heap.\033[0m"
}

jmapHisto(){
    # jmap -histo
    JMAP_HISTO_LOG=jmap_histo-${PID}-${DATE}.log
    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Begin to process jmap -histo. write into $JMAP_HISTO_LOG\033[0m"
    
    jmap -histo $PID > ${JMAP_HISTO_LOG}
    if [[ $? != 0 ]]; then
        echo -e "\033[31mprocess jmap -histo error.\033[0m"
    fi
    echo -e "\033[34m$(date '+%Y-%m-%d %H:%M:%S') Finish to process jmap -histo.\033[0m\n"
    sleep ${SLEEP_TIME}
}

needFullGC(){
    echo -e "\033[41;37m###################################\033[0m\n"
    echo -e "\033[31mBelow cmd need full GC, do it if you need!\033[0m"

    JMAP_HISTO_LIVE_LOG=jmap_histo_live-${PID}-${DATE}.log
    echo "jmap -histo:live $PID > ${JMAP_HISTO_LIVE_LOG}"

    JMAP_DUMP_FILE=jmap_dump_live-${PID}-${DATE}.bin
    echo "jmap -dump:live,format=b,file=${JMAP_DUMP_FILE} $PID"

    echo -e "\n\033[41;37m###################################\033[0m\n"

}

suggest(){
    echo -e "\nSuggest maybe!\n"
    echo -e "jstat -gcutil $PID 1000 10"
    echo -e "sar"
    echo -e "dmesg | grep oom"
    echo ""
}

pidAndChoice(){
    while [[ "x" == "x$PID" ]]; do
        # do ps java
        psjava
        if [[ "x" == "x$PID" ]];then
            read -p "Please enter PID:" PID
        fi
    done

    echo -e "\033[35mThe PID is $PID\033[0m"
    echo ""
    echo "1. CPU"
    echo "2. Memory"
    echo "8. Suggest"
    echo "9. ALL"
    read -p "Please enter your choice (default 9):" choice 
    
    if [[ "x" == "x$choice" ]]; then
        choice='9'
    fi

    echo ""
    echo -e "\033[35mThe choice is $choice\033[0m"
}

main(){

    pidAndChoice

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
    fi

    suggest
    echo ""
    echo "End cjvmtools.sh"
}

main
