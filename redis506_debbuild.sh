#!/usr/bin/env bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
cur_dir=$(pwd)

include(){
    local include=${1}
    if [[ -s ${cur_dir}/tmps/include/${include}.sh ]];then
        . ${cur_dir}/tmps/include/${include}.sh
    else
        wget --no-check-certificate -cv -t3 -T60 -P tmps/include http://d.hws.com/linux/master/script/include/${include}.sh >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
            echo "Error: ${cur_dir}/tmps/include/${include}.sh not found, shell can not be executed."
            exit 1
        fi
        . ${cur_dir}/tmps/include/${include}.sh
    fi
}

_create_sysv_file(){
    cat > /etc/init.d/redis << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: redis service script

### BEGIN INIT INFO
# Provides:          redis506
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: redis
# Description:       redis service script
### END INIT INFO

prefix={redis_location}

NAME=redis-server
BIN=$prefix/bin/$NAME
PID_FILE=$prefix/var/run/redis.pid
CONFIG_FILE=$prefix/etc/redis.conf

wait_for_pid () {
    try=0
    while test $try -lt 35 ; do
        case "$1" in
            'created')
            if [ -f "$2" ] ; then
                try=''
                break
            fi
            ;;
            'removed')
            if [ ! -f "$2" ] ; then
                try=''
                break
            fi
            ;;
        esac
        echo -n .
        try=`expr $try + 1`
        sleep 1
    done
}

start()
{
    echo -n "Starting $NAME..."
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid $mPID) already running."
            exit 1
        fi
    fi
    $BIN $CONFIG_FILE
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    fi
    wait_for_pid created $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

stop()
{
    echo -n "Stoping $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" = '' ];then
            echo "$NAME is not running."
            exit 1
        fi
    else
        echo "PID file found, $NAME is not running ?"
        exit 1
    fi
    kill -TERM `cat $PID_FILE`
    wait_for_pid removed $PID_FILE
    if [ -n "$try" ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

restart(){
    $0 stop
    $0 start
}

status(){
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid $mPID) is running."
            exit 0
        else
            echo "$NAME already stopped."
            exit 1
        fi
    else
        echo "$NAME already stopped."
        exit 1
    fi
}

reload() {
    echo -n "Reload service $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            kill -USR2 `cat $PID_FILE`
            echo " done"
        else
            echo "$NAME is not running, can't reload."
            exit 1
        fi
    else
        echo "$NAME is not running, can't reload."
        exit 1
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    reload)
        reload
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|reload}"
esac
EOF
    sed -i "s|^prefix={redis_location}$|prefix=${redis_location}|g" /etc/init.d/redis
}

debbuild_redis506(){
    redis_port=6379
    redis_location=/hws.com/hwsmaster/server/redis5_0_6

    local tram=$( free -m | awk '/Mem/ {print $2}' )
    local swap=$( free -m | awk '/Swap/ {print $2}' )
    local Mem=$(expr $tram + $swap)
    cd /tmp
    _info "redis-server install start..."
    DownloadFile "${redis506_filename}.tar.gz" "${redis506_download_url}"
    rm -fr ${redis506_filename}
    tar zxf ${redis506_filename}.tar.gz
    cd ${redis506_filename}
    ! Is64bit && sed -i '1i\CFLAGS= -march=i686' src/Makefile && sed -i 's@^OPT=.*@OPT=-O2 -march=i686@' src/.make-settings
    CheckError "make"
    if [ -f "src/redis-server" ]; then
        mkdir -p ${redis_location}/{bin,etc,var}
        mkdir -p ${redis_location}/var/{log,run}
        cp src/redis-benchmark ${redis_location}/bin
        cp src/redis-check-aof ${redis_location}/bin
        cp src/redis-check-rdb ${redis_location}/bin
        cp src/redis-cli ${redis_location}/bin
        cp src/redis-sentinel ${redis_location}/bin
        cp src/redis-server ${redis_location}/bin
        # Config
        _info "Config ${redis506_filename}"
        cp redis.conf ${redis_location}/etc/
        sed -i "s@pidfile.*@pidfile ${redis_location}/var/run/redis.pid@" ${redis_location}/etc/redis.conf
        sed -i "s@logfile.*@logfile ${redis_location}/var/log/redis.log@" ${redis_location}/etc/redis.conf
        sed -i "s@^dir.*@dir ${redis_location}/var@" ${redis_location}/etc/redis.conf
        sed -i 's@daemonize no@daemonize yes@' ${redis_location}/etc/redis.conf
        sed -i "s@port 6379@port ${redis_port}@" ${redis_location}/etc/redis.conf
        sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_location}/etc/redis.conf
        [ -z "$(grep ^maxmemory ${redis_location}/etc/redis.conf)" ] && sed -i "s@maxmemory <bytes>@maxmemory <bytes>\nmaxmemory $(expr ${Mem} / 8)000000@" ${redis_location}/etc/redis.conf
        # Start
        _create_sysv_file
        chmod +x /etc/init.d/redis
        update-rc.d -f redis defaults > /dev/null 2>&1
        /etc/init.d/redis start
        # Clean
        rm -fr ${redis506_filename}
        _success "redis-server install completed!"
        # Build
        _info "Build deb..."
        _build_deb
    else
        _warn "redis-server install failed."
    fi
}


_build_deb(){
    cd /tmp
    buildroot=/tmp/buildroot
    mkdir -p ${buildroot}
    mkdir -p ${buildroot}/DEBIAN
    cp -a --parents ${redis_location} ${buildroot}
    cp -a --parents /etc/init.d/redis ${buildroot}

    cat > ${buildroot}/DEBIAN/control << EOF
Package: hws-redis
Version: 5.0.6
Section: database
Priority: optional
Architecture: amd64
Eseential: no
Maintainer: Jerry Wang[1976883731@qq.com]
Description: redis build by hws
Homepage: https://www.hws.com
EOF

    cat > ${buildroot}/DEBIAN/postinst << 'EOF'
update-rc.d -f redis defaults >/dev/null 2>&1
[ $? -ne 0 ] && echo "[ERROR]: update-rc.d -f redis defaults"
/etc/init.d/redis start
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/postinst

    cat > ${buildroot}/DEBIAN/prerm << 'EOF'
/etc/init.d/redis stop > /dev/null 2>&1
update-rc.d -f redis remove >/dev/null 2>&1
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/prerm

    dpkg-deb -b ${buildroot} redis-5.0.6-linux-amd64.deb
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    debbuild_redis506
}
main "$@" |tee /tmp/install.log
