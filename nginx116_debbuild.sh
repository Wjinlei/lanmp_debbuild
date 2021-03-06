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

_install_nginx_depend(){
    _info "Starting to install dependencies packages for Nginx..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(zlib-devel)
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(zlib1g-dev)
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -d /home/www -s /sbin/nologin
    mkdir -p ${nginx_location}
    _success "Install dependencies packages for Nginx completed..."
}

_create_config_file(){
    # 备份原配置文件
    [ -f "${nginx_location}/etc/nginx.conf" ] && \
        mv ${nginx_location}/etc/nginx.conf ${nginx_location}/etc/nginx.conf-$(date +%Y-%m-%d_%H:%M:%S).bak

    # 写入默认配置文件
    cat > ${nginx_location}/etc/nginx.conf <<EOF
worker_processes auto;
worker_rlimit_nofile 51200;

events {
    use epoll;
    worker_connections 51200;
    multi_accept on;
}

http {
    include mime.types;
    default_type application/octet-stream;
    server_names_hash_bucket_size 512;
    client_max_body_size 50m;
    client_header_buffer_size 32k;
    client_body_buffer_size 128k;
    large_client_header_buffers 4 32k;

    sendfile   on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 60;

    # fastcgi
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 256k;
    fastcgi_intercept_errors on;

    # gzip
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/javascript application/json application/javascript application/x-javascript application/xml;
    gzip_vary on;

    # http_proxy
    proxy_connect_timeout 75;
    proxy_send_timeout 75;
    proxy_read_timeout 75;
    proxy_buffer_size 4k;
    proxy_buffers 4 32k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size 64k;

    server_tokens off;
    limit_conn_zone \$binary_remote_addr zone=perip:10m;
    limit_conn_zone \$server_name zone=perserver:10m;

    # include virtual host config
    include vhost/*.conf;
    include ${var}/default/wwwconf/nginx/*.conf;
    include ${var}/wwwconf/nginx/*.conf;

    server {
       listen 80 default;
       return 403;
    }
}
EOF
}

_create_sysv_script() {
    cat > /etc/init.d/nginx <<'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: nginx service script

### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nginx
# Description:       nginx service script
### END INIT INFO

prefix={nginx_location}

NAME=nginx
PID_FILE=$prefix/var/run/$NAME.pid
BIN=$prefix/sbin/$NAME
CONFIG_FILE=$prefix/etc/$NAME.conf

ulimit -n 10240
start()
{
    echo -n "Starting $NAME..."
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid `pidof $NAME`) already running."
            exit 1
        fi
    fi
    $BIN -c $CONFIG_FILE
    if [ "$?" != 0 ] ; then
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
    $BIN -s stop
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
}

restart(){
    $0 stop
    sleep 1
    $0 start
}

reload() {
    echo -n "Reload service $NAME... "
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            $BIN -s reload
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

status(){
    if [ -f $PID_FILE ];then
        mPID=`cat $PID_FILE`
        isRunning=`ps ax | awk '{ print $1 }' | grep -e "^${mPID}$"`
        if [ "$isRunning" != '' ];then
            echo "$NAME (pid `pidof $NAME`) is running."
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

configtest() {
    echo "Test $NAME configure files... "
    $BIN -t
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
    test)
        configtest
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|test}"
esac
EOF
sed -i "s|^prefix={nginx_location}$|prefix=${nginx_location}|g" /etc/init.d/nginx
}

_create_logrotate_file(){
    # 定期清理日志
    cat > /etc/logrotate.d/nginx-logs <<EOF
${nginx_location}/var/log/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}
EOF
    cat > /etc/logrotate.d/nginx-wwwlogs <<EOF
${var}/default/wwwlogs/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}

${var}/default/wwwlogs/nginx/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}

${var}/wwwlogs/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        [ ! -f ${nginx_location}/var/run/nginx.pid ] || kill -USR1 \`cat ${nginx_location}/var/run/nginx.pid\`
    endscript
}
EOF
}

debbuild_nginx116(){
    nginx_location=/hws.com/hwsmaster/server/nginx-1_16_1

    _install_nginx_depend
    cd /tmp
    _info "Downloading and Extracting ${pcre_filename} files..."
    DownloadFile "${pcre_filename}.tar.gz" ${pcre_download_url}
    _info "Downloading and Extracting ${openssl102_filename} files..."
    DownloadFile "${openssl102_filename}.tar.gz" ${openssl102_download_url}
    _info "Downloading and Extracting ${nginx116_filename} files..."
    DownloadFile "${nginx116_filename}.tar.gz" ${nginx116_download_url}
    tar zxf ${pcre_filename}.tar.gz
    tar zxf ${openssl102_filename}.tar.gz
    tar zxf ${nginx116_filename}.tar.gz
    # Make install
    cd ${nginx116_filename}
    nginx_configure_args="--prefix=${nginx_location} \
    --conf-path=${nginx_location}/etc/nginx.conf \
    --error-log-path=${nginx_location}/var/log/error.log \
    --pid-path=${nginx_location}/var/run/nginx.pid \
    --lock-path=${nginx_location}/var/lock/nginx.lock \
    --http-log-path=${nginx_location}/var/log/access.log \
    --http-client-body-temp-path=${nginx_location}/var/tmp/client \
    --http-proxy-temp-path=${nginx_location}/var/tmp/proxy \
    --http-fastcgi-temp-path=${nginx_location}/var/tmp/fastcgi \
    --http-uwsgi-temp-path=${nginx_location}/var/tmp/uwsgi \
    --http-scgi-temp-path=${nginx_location}/var/tmp/scgi \
    --with-pcre=/tmp/${pcre_filename} \
    --with-openssl=/tmp/${openssl102_filename} \
    --with-compat \
    --user=www \
    --group=www \
    --with-stream \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_stub_status_module"
    _info "Make Install ${nginx116_filename}..."
    CheckError "./configure ${nginx_configure_args}"
    CheckError "parallel_make"
    CheckError "make install"
    mkdir -p ${nginx_location}/var/{log,run,lock,tmp}
    mkdir -p ${nginx_location}/var/tmp/{client,proxy,fastcgi,uwsgi}
    mkdir -p ${nginx_location}/etc/vhost
    # Config
    _info "Config ${nginx116_filename}"
    _create_logrotate_file
    _create_config_file
    mkdir -p ${var}/wwwlogs
    mkdir -p ${var}/wwwconf/nginx
    mkdir -p ${var}/default/wwwlogs
    mkdir -p ${var}/default/wwwconf/nginx
    # Start
    _create_sysv_script
    chmod +x /etc/init.d/nginx
    update-rc.d -f nginx defaults >/dev/null 2>&1
    /etc/init.d/nginx start
    # Clean
    _info "Clean installed..."
    rm -fr /tmp/${pcre_filename}
    rm -fr /tmp/${openssl102_filename}
    rm -fr /tmp/${nginx116_filename}
    _success "${nginx116_filename} install completed..."
    # Build
    _info "Build deb..."
    _build_deb
}

_build_deb(){
    cd /tmp
    buildroot=/tmp/buildroot
    mkdir -p ${buildroot}
    mkdir -p ${buildroot}/DEBIAN
    cp -a --parents ${nginx_location} ${buildroot}
    cp -a --parents /etc/logrotate.d/nginx-logs ${buildroot}
    cp -a --parents /etc/logrotate.d/nginx-wwwlogs ${buildroot}
    cp -a --parents /etc/init.d/nginx ${buildroot}

    cat > ${buildroot}/DEBIAN/control << EOF
Package: hws-nginx
Version: 1.16.1
Section: web
Priority: optional
Architecture: amd64
Eseential: no
Depends: zlib1g-dev
Maintainer: Jerry Wang[1976883731@qq.com]
Description: nginx build by hws
Homepage: https://www.hws.com
EOF

    cat > ${buildroot}/DEBIAN/postinst << 'EOF'
id -u www >/dev/null 2>&1
[ $? -ne 0 ] && useradd -M -U www -d /home/www -s /sbin/nologin
update-rc.d -f nginx defaults >/dev/null 2>&1
[ $? -ne 0 ] && echo "[ERROR]: update-rc.d -f nginx defaults"
/etc/init.d/nginx start
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/postinst

    cat > ${buildroot}/DEBIAN/prerm << 'EOF'
/etc/init.d/nginx stop > /dev/null 2>&1
update-rc.d -f nginx remove >/dev/null 2>&1
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/prerm

    dpkg-deb -b ${buildroot} nginx-1.16.1-linux-amd64.deb
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    debbuild_nginx116
}
main "$@" |tee /tmp/install.log
