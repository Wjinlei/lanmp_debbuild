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

_install_php_depend(){
    _info "Starting to install dependencies packages for PHP..."
    if [ "${PM}" = "yum" ];then
        local yum_depends=(
            autoconf patch m4 bison bzip2-devel pam-devel gmp-devel
            pcre-devel libtool-libs libtool-ltdl-devel libwebp-devel
            libvpx-devel libjpeg-devel libpng-devel oniguruma-devel
            aspell-devel enchant-devel readline-devel unixODBC-devel
            libxslt-devel sqlite-devel libiodbc-devel php-odbc zlib-devel
            libXpm-devel libtidy-devel freetype-devel python2-devel
        )
        for depend in ${yum_depends[@]}
        do
            InstallPack "yum -y install ${depend}"
        done
        _install_mhash
        _install_libmcrypt
        _install_mcrypt
        _install_libzip
    elif [ "${PM}" = "apt-get" ];then
        local apt_depends=(
            autoconf patch m4 bison libbz2-dev libgmp-dev libldb-dev
            libpam0g-dev autoconf2.13 pkg-config libxslt1-dev zlib1g-dev
            libpcre3-dev libtool libjpeg-dev libpng-dev libpspell-dev
            libmhash-dev libenchant-dev libwebp-dev libxpm-dev libvpx-dev
            libreadline-dev libzip-dev libmcrypt-dev unixodbc-dev
            libtidy-dev python-dev libonig-dev
        )
        for depend in ${apt_depends[@]}
        do
            InstallPack "apt-get -y install ${depend}"
        done
        if Is64bit; then
            if [ ! -d /usr/lib64 ] && [ -d /usr/lib ]; then
                ln -sf /usr/lib /usr/lib64
            fi

            if [ -f /usr/include/gmp-x86_64.h ]; then
                ln -sf /usr/include/gmp-x86_64.h /usr/include/
            elif [ -f /usr/include/x86_64-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/
            fi

            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.a ] && [ ! -f /usr/lib64/libXpm.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libXpm.so ] && [ ! -f /usr/lib64/libXpm.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.a ] && [ ! -f /usr/lib64/libjpeg.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.so ] && [ ! -f /usr/lib64/libjpeg.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.a ] && [ ! -f /usr/lib64/libpng.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib64
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.so ] && [ ! -f /usr/lib64/libpng.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib64
            fi
        else
            if [ -f /usr/include/gmp-i386.h ]; then
                ln -sf /usr/include/gmp-i386.h /usr/include/
            elif [ -f /usr/include/i386-linux-gnu/gmp.h ]; then
                ln -sf /usr/include/i386-linux-gnu/gmp.h /usr/include/
            fi

            if [ -f /usr/lib/i386-linux-gnu/libXpm.a ] && [ ! -f /usr/lib/libXpm.a ]; then
                ln -sf /usr/lib/i386-linux-gnu/libXpm.a /usr/lib
            fi
            if [ -f /usr/lib/i386-linux-gnu/libXpm.so ] && [ ! -f /usr/lib/libXpm.so ]; then
                ln -sf /usr/lib/i386-linux-gnu/libXpm.so /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.a ] && [ ! -f /usr/lib/libjpeg.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libjpeg.so ] && [ ! -f /usr/lib/libjpeg.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.a ] && [ ! -f /usr/lib/libpng.a ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib
            fi
            if [ -f /usr/lib/x86_64-linux-gnu/libpng.so ] && [ ! -f /usr/lib/libpng.so ]; then
                ln -sf /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib
            fi
        fi
        _install_freetype
    fi
    _install_openssl102
    _install_pcre
    _install_re2c
    _install_icu4c
    _install_libxml2
    _install_libiconv
    _install_curl
    _success "Install dependencies packages for PHP completed..."
    # Fixed unixODBC issue
    if [ -f /usr/include/sqlext.h ] && [ ! -f /usr/local/include/sqlext.h ]; then
        ln -sf /usr/include/sqlext.h /usr/local/include/
    fi
    id -u www >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -U www -d /home/www -s /sbin/nologin
    mkdir -p ${php55_location}
}

_install_openssl102(){
    cd /tmp
    _info "${openssl102_filename} install start..."
    rm -fr ${openssl102_filename}
    DownloadFile "${openssl102_filename}.tar.gz" "${openssl102_download_url}"
    tar zxf ${openssl102_filename}.tar.gz
    cd ${openssl102_filename}
    CheckError "./config --prefix=${openssl102_location} --openssldir=${openssl102_location} -fPIC shared zlib"
    CheckError "parallel_make"
    CheckError "make install"

    #Debian8
    if Is64bit; then
        if [ -f /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libssl.a /usr/lib/x86_64-linux-gnu
            ln -sf ${openssl102_location}/lib/libssl.so /usr/lib/x86_64-linux-gnu
            ln -sf ${openssl102_location}/lib/libssl.so.1.0.0 /usr/lib/x86_64-linux-gnu
        fi
        if [ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libcrypto.a /usr/lib/x86_64-linux-gnu
            ln -sf ${openssl102_location}/lib/libcrypto.so /usr/lib/x86_64-linux-gnu
            ln -sf ${openssl102_location}/lib/libcrypto.so.1.0.0 /usr/lib/x86_64-linux-gnu
        fi
    else
        if [ -f /usr/lib/i386-linux-gnu/libssl.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libssl.a /usr/lib/i386-linux-gnu
            ln -sf ${openssl102_location}/lib/libssl.so /usr/lib/i386-linux-gnu
            ln -sf ${openssl102_location}/lib/libssl.so.1.0.0 /usr/lib/i386-linux-gnu
        fi
        if [ -f /usr/lib/i386-linux-gnu/libcrypto.so.1.0.0 ]; then
            ln -sf ${openssl102_location}/lib/libcrypto.a /usr/lib/i386-linux-gnu
            ln -sf ${openssl102_location}/lib/libcrypto.so /usr/lib/i386-linux-gnu
            ln -sf ${openssl102_location}/lib/libcrypto.so.1.0.0 /usr/lib/i386-linux-gnu
        fi
    fi

    AddToEnv "${openssl102_location}"
    CreateLib64Dir "${openssl102_location}"
    export PKG_CONFIG_PATH=${openssl102_location}/lib/pkgconfig:$PKG_CONFIG_PATH
    if ! grep -qE "^${openssl102_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${openssl102_location}/lib" > /etc/ld.so.conf.d/openssl102.conf
    fi
    ldconfig

    _success "${openssl102_filename} install completed..."
    rm -f /tmp/${openssl102_filename}.tar.gz
    rm -fr /tmp/${openssl102_filename}
}

_install_pcre(){
    cd /tmp
    _info "${pcre_filename} install start..."
    rm -fr ${pcre_filename}
    DownloadFile "${pcre_filename}.tar.gz" "${pcre_download_url}"
    tar zxf ${pcre_filename}.tar.gz
    cd ${pcre_filename}
    CheckError "./configure --prefix=${pcre_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${pcre_location}"
    CreateLib64Dir "${pcre_location}"
    if ! grep -qE "^${pcre_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${pcre_location}/lib" > /etc/ld.so.conf.d/pcre.conf
    fi
    ldconfig
    _success "${pcre_filename} install completed..."
    rm -f /tmp/${pcre_filename}.tar.gz
    rm -fr /tmp/${pcre_filename}
}

_install_icu4c() {
    cd /tmp
    _info "${icu4c_filename} install start..."
    rm -fr ${icu4c_dirname}
    DownloadFile "${icu4c_filename}.tgz" "${icu4c_download_url}"
    tar zxf ${icu4c_filename}.tgz
    cd ${icu4c_dirname}/source
    CheckError "./configure --prefix=${icu4c_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${icu4c_location}"
    CreateLib64Dir "${icu4c_location}"
    if ! grep -qE "^${icu4c_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${icu4c_location}/lib" > /etc/ld.so.conf.d/icu4c.conf
    fi
    ldconfig
    _success "${icu4c_filename} install completed..."
    rm -f /tmp/${icu4c_filename}.tgz
    rm -fr /tmp/${icu4c_dirname}
}

_install_libxml2() {
    cd /tmp
    _info "${libxml2_filename} install start..."
    rm -fr ${libxml2_filename}
    DownloadFile "${libxml2_filename}.tar.gz" "${libxml2_download_url}"
    tar zxf ${libxml2_filename}.tar.gz
    cd ${libxml2_filename}
    CheckError "./configure --prefix=${libxml2_location} --with-icu=${icu4c_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${libxml2_location}"
    CreateLib64Dir "${libxml2_location}"
    if ! grep -qE "^${libxml2_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${libxml2_location}/lib" > /etc/ld.so.conf.d/libxml2.conf
    fi
    ldconfig
    _success "${libxml2_filename} install completed..."
    rm -f /tmp/${libxml2_filename}.tar.gz
    rm -fr /tmp/${libxml2_filename}
}

_install_curl(){
    cd /tmp
    _info "${curl_filename} install start..."
    rm -fr ${curl_filename}
    DownloadFile "${curl_filename}.tar.gz" "${curl_download_url}"
    tar zxf ${curl_filename}.tar.gz
    cd ${curl_filename}
    CheckError "./configure --prefix=${curl102_location} --with-ssl=${openssl102_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${curl102_location}"
    CreateLib64Dir "${curl102_location}"
    _success "${curl_filename} install completed..."
    rm -f /tmp/${curl_filename}.tar.gz
    rm -fr /tmp/${curl_filename}
}

_install_libiconv(){
    cd /tmp
    _info "${libiconv_filename} install start..."
    DownloadFile "${libiconv_filename}.tar.gz" "${libiconv_download_url}"
    rm -fr ${libiconv_filename}
    tar zxf ${libiconv_filename}.tar.gz
    DownloadFile "${libiconv_patch_filename}.tar.gz" "${libiconv_patch_download_url}"
    rm -f ${libiconv_patch_filename}.patch
    tar zxf ${libiconv_patch_filename}.tar.gz
    patch -d ${libiconv_filename} -p0 < ${libiconv_patch_filename}.patch
    cd ${libiconv_filename}
    CheckError "./configure --prefix=${libiconv_location}"
    CheckError "parallel_make"
    CheckError "make install"
    AddToEnv "${libiconv_location}"
    CreateLib64Dir "${libiconv_location}"
    if ! grep -qE "^${libiconv_location}/lib" /etc/ld.so.conf.d/*.conf; then
        echo "${libiconv_location}/lib" > /etc/ld.so.conf.d/libiconv.conf
    fi
    ldconfig
    _success "${libiconv_filename} install completed..."
    rm -fr /tmp/${libiconv_filename}
    rm -f /tmp/${libiconv_filename}.tar.gz
    rm -f /tmp/${libiconv_patch_filename}.tar.gz
    rm -f /tmp/${libiconv_patch_filename}.patch
}

_install_re2c(){
    cd /tmp
    _info "${re2c_filename} install start..."
    DownloadFile "${re2c_filename}.tar.xz" "${re2c_download_url}"
    tar Jxf ${re2c_filename}.tar.xz
    cd ${re2c_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${re2c_filename} install completed..."
    rm -f /tmp/${re2c_filename}.tar.xz
    rm -fr /tmp/${re2c_filename}
}

_install_mhash(){
    cd /tmp
    _info "${mhash_filename} install start..."
    DownloadFile "${mhash_filename}.tar.gz" "${mhash_download_url}"
    tar zxf ${mhash_filename}.tar.gz
    cd ${mhash_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${mhash_filename} install completed..."
    rm -f /tmp/${mhash_filename}.tar.gz
    rm -fr /tmp/${mhash_filename}
}

_install_mcrypt(){
    cd /tmp
    _info "${mcrypt_filename} install start..."
    DownloadFile "${mcrypt_filename}.tar.gz" "${mcrypt_download_url}"
    tar zxf ${mcrypt_filename}.tar.gz
    cd ${mcrypt_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${mcrypt_filename} install completed..."
    rm -f /tmp/${mcrypt_filename}.tar.gz
    rm -fr /tmp/${mcrypt_filename}
}

_install_libmcrypt(){
    cd /tmp
    _info "${libmcrypt_filename} install start..."
    DownloadFile "${libmcrypt_filename}.tar.gz" "${libmcrypt_download_url}"
    tar zxf ${libmcrypt_filename}.tar.gz
    cd ${libmcrypt_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${libmcrypt_filename} install completed..."
    rm -f /tmp/${libmcrypt_filename}.tar.gz
    rm -fr /tmp/${libmcrypt_filename}
}

_install_libzip(){
    cd /tmp
    _info "${libzip_filename} install start..."
    DownloadFile "${libzip_filename}.tar.gz" "${libzip_download_url}"
    tar zxf ${libzip_filename}.tar.gz
    cd ${libzip_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${libzip_filename} install completed..."
    rm -f /tmp/${libzip_filename}.tar.gz
    rm -fr /tmp/${libzip_filename}
}

_install_freetype() {
    cd /tmp
    _info "${freetype_filename} install start..."
    rm -fr ${freetype_filename}
    DownloadFile "${freetype_filename}.tar.gz" "${freetype_download_url}"
    tar zxf ${freetype_filename}.tar.gz
    cd ${freetype_filename}
    CheckError "./configure"
    CheckError "parallel_make"
    CheckError "make install"
    ldconfig
    _success "${freetype_filename} install completed..."
    rm -f /tmp/${freetype_filename}.tar.gz
    rm -fr /tmp/${freetype_filename}

}

_create_sysv_file(){
    cat > /etc/init.d/php55 << 'EOF'
#!/bin/bash
# chkconfig: 2345 55 25
# description: php-fpm service script

### BEGIN INIT INFO
# Provides:          php55-fpm
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: php-fpm
# Description:       php-fpm service script
### END INIT INFO

prefix={php-fpm_location}

NAME=php-fpm
BIN=$prefix/sbin/$NAME
PID_FILE=$prefix/var/run/default.pid
CONFIG_FILE=$prefix/etc/default.conf

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
    $BIN --daemonize --fpm-config $CONFIG_FILE --pid $PID_FILE
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
    kill -QUIT `cat $PID_FILE`
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

reload() {
    echo -n "Reload service $NAME... "
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
    kill -USR2 `cat $PID_FILE`
    if [ "$?" != 0 ] ; then
        echo " failed"
        exit 1
    else
        echo " done"
    fi
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

force-stop() {
    echo -n "force-stop $NAME "
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
    force-stop)
        force-stop
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status|force-stop}"
esac
EOF
    sed -i "s|^prefix={php-fpm_location}$|prefix=${php55_location}|g" /etc/init.d/php55
}

_config_php(){
    # php.ini
    mkdir -p ${php55_location}/{etc,php.d}
    cp -f php.ini-production ${php55_location}/etc/php.ini

    sed -i 's/;default_charset =.*/default_charset = "UTF-8"/g' ${php55_location}/etc/php.ini
    sed -i 's/;always_populate_raw_post_data =.*/always_populate_raw_post_data = -1/g' ${php55_location}/etc/php.ini
    sed -i 's/post_max_size =.*/post_max_size = 100M/g' ${php55_location}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 100M/g' ${php55_location}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php55_location}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php55_location}/etc/php.ini
    sed -i 's/expose_php =.*/expose_php = Off/g' ${php55_location}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php55_location}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php55_location}/etc/php.ini
    if [ -f /etc/pki/tls/certs/ca-bundle.crt ]; then
        sed -i 's#;curl.cainfo =.*#curl.cainfo = /etc/pki/tls/certs/ca-bundle.crt#g' ${php55_location}/etc/php.ini
        sed -i 's#;openssl.cafile=.*#openssl.cafile=/etc/pki/tls/certs/ca-bundle.crt#g' ${php55_location}/etc/php.ini
    elif [ -f /etc/ssl/certs/ca-certificates.crt ]; then
        sed -i 's#;curl.cainfo =.*#curl.cainfo = /etc/ssl/certs/ca-certificates.crt#g' ${php55_location}/etc/php.ini
        sed -i 's#;openssl.cafile=.*#openssl.cafile=/etc/ssl/certs/ca-certificates.crt#g' ${php55_location}/etc/php.ini
    fi
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,proc_open,pcntl_exec,ini_alter,ini_restore,dl,openlog,syslog,popepassthru,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,imap_open,apache_setenv/g' ${php55_location}/etc/php.ini

    extension_dir=$(${php55_location}/bin/php-config --extension-dir)

    Is64bit && sys_bit=x86_64 || sys_bit=i686
    if [ "${sys_bit}" == "x86_64" ]; then
        DownloadFile  "${zend_loader_php55_x86_64_filename}_update1.tar.gz" "${zend_loader_php55_x86_64_download_url}"
        tar zxf ${zend_loader_php55_x86_64_filename}_update1.tar.gz
        cp -f ${zend_loader_php55_x86_64_filename}/opcache.so ${extension_dir}
        cp -f ${zend_loader_php55_x86_64_filename}/ZendGuardLoader.so ${extension_dir}
    elif [ "${sys_bit}" == "i686" ]; then
        DownloadFile  "${zend_loader_php55_i386_filename}_update1.tar.gz" "${zend_loader_php55_i386_download_url}"
        tar zxf ${zend_loader_php55_i386_filename}_update1.tar.gz
        cp -f ${zend_loader_php55_i386_filename}/opcache.so ${extension_dir}
        cp -f ${zend_loader_php55_i386_filename}/ZendGuardLoader.so ${extension_dir}
    fi

    cat > ${php55_location}/php.d/zendloader.ini<<EOF
[ZendGuardLoader]
zend_extension=${extension_dir}/ZendGuardLoader.so
zend_loader.enable=1
EOF

    cat > ${php55_location}/php.d/opcache.ini<<EOF
[opcache]
zend_extension=${extension_dir}/opcache.so
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.save_comments=1
EOF

    # php-fpm
    cat > ${php55_location}/etc/default.conf<<EOF
[global]
    pid = ${php55_location}/var/run/default.pid
    error_log = ${php55_location}/var/log/default.log
[default]
    security.limit_extensions = .php .php3 .php4 .php5 .php7
    listen = /tmp/${php55_filename}-default.sock
    listen.owner = www
    listen.group = www
    listen.mode = 0660
    listen.allowed_clients = 127.0.0.1
    user = www
    group = www
    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3
EOF
    mkdir -p ${php55_location}/var/run
    mkdir -p ${php55_location}/var/log
}

debbuild_php55(){
    php55_location=/hws.com/hwsmaster/server/php-5_5_38

    _install_php_depend
    cd /tmp
    _info "Downloading and Extracting ${php55_filename} files..."
    DownloadFile  "${php55_filename}.tar.gz" "${php55_download_url}"
    rm -fr ${php55_filename}
    tar zxf ${php55_filename}.tar.gz
    cd ${php55_filename}
    _info "Install ${php55_filename} ..."
    Is64bit && with_libdir="--with-libdir=lib64" || with_libdir=""
    php_configure_args="--prefix=${php55_location} \
    --with-config-file-path=${php55_location}/etc \
    --with-config-file-scan-dir=${php55_location}/php.d \
    --with-libxml-dir=${libxml2_location} \
    --with-pcre-dir=${pcre_location} \
    --with-openssl=${openssl102_location} \
    ${with_libdir} \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pdo-mysql=mysqlnd \
    --with-gd \
    --with-vpx-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-xpm-dir \
    --with-freetype-dir \
    --with-zlib \
    --with-bz2 \
    --with-curl=${curl102_location} \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --with-icu-dir=${icu4c_location} \
    --with-libmbfl \
    --with-onig \
    --with-unixODBC \
    --with-pspell=/usr \
    --with-enchant=/usr \
    --with-readline \
    --with-tidy=/usr \
    --with-xmlrpc \
    --with-xsl \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-iconv=${libiconv_location} \
    --without-pear \
    --disable-phar \
    --with-mcrypt \
    --enable-gd-native-ttf \
    --enable-mysqlnd \
    --enable-fpm \
    --enable-bcmath \
    --enable-calendar \
    --enable-dba \
    --enable-exif \
    --enable-ftp \
    --enable-gd-jis-conv \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-wddx \
    --enable-zip \
    ${disable_fileinfo}"
    unset LD_LIBRARY_PATH
    unset CPPFLAGS
    ldconfig
    CheckError "./configure ${php_configure_args}"
    CheckError "parallel_make ZEND_EXTRA_LIBS='-liconv'"
    CheckError "make install"
    # Config
    _info "Config ${php55_filename}..."
    _config_php
    # Start
    _create_sysv_file
    chmod +x /etc/init.d/php55
    update-rc.d -f php55 defaults > /dev/null 2>&1
    /etc/init.d/php55 start
    _warn "Please add the following two lines to your httpd.conf"
    echo AddType application/x-httpd-php .php .phtml
    echo AddType application/x-httpd-php-source .phps
    # Clean
    rm -fr /tmp/${php55_filename}
    _success "${php55_filename} install completed..."
    # Build
    _info "Build deb..."
    _build_deb
}

_build_deb(){
    cd /tmp
    buildroot=/tmp/buildroot
    mkdir -p ${buildroot}
    mkdir -p ${buildroot}/DEBIAN
    # Copy files
    cp -a --parents ${php55_location} ${buildroot}
    cp -a --parents /etc/init.d/php55 ${buildroot}
    mkdir -p ${buildroot}/etc/ld.so.conf.d
    mkdir -p ${buildroot}${php55_location}/lib
    cd ${buildroot}${php55_location}/lib
    # Fix libtidy
    cp -a /usr/lib/libtidy-0.99.so.0 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/libtidy-0.99.so.0.0.0 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/libtidy.a ${buildroot}${php55_location}/lib
    cp -a /usr/lib/libtidy.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/libtidy.la ${buildroot}${php55_location}/lib
    # Fix libreadline
    cp -a /usr/lib/x86_64-linux-gnu/libreadline.a ${buildroot}${php55_location}/lib
    cp -a /lib/x86_64-linux-gnu/libreadline.so.6 ${buildroot}${php55_location}/lib
    cp -a /lib/x86_64-linux-gnu/libreadline.so.6.3 ${buildroot}${php55_location}/lib
    ln -s libreadline.so.6 libreadline.so
    # Fix libvpx
    cp -a /usr/lib/x86_64-linux-gnu/libvpx.so.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libvpx.so.1.3.0 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libvpx.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libvpx.so.1.3 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libvpx.a ${buildroot}${php55_location}/lib
    # Fix libtinfo
    libtinfo5_filename="libtinfo5"
    DownloadUrl ${libtinfo5_filename}.tar.gz http://test.hws.com/wangjinlei/${libtinfo5_filename}.tar.gz
    tar -xf ${libtinfo5_filename}.tar.gz -C  ${buildroot}${php55_location}/lib
    # Fix libzip
    cp -a /usr/lib/x86_64-linux-gnu/libzip.a ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libzip.so.2.1.0 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libzip.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libzip.so.2 ${buildroot}${php55_location}/lib
    # Fix libz
    #cp -a /lib/x86_64-linux-gnu/libz.so.1.2.8 ${buildroot}${php55_location}/lib
    #cp -a /usr/lib/x86_64-linux-gnu/libz.a ${buildroot}${php55_location}/lib
    #ln -s libz.so.1.2.8 libz.so.1
    #ln -s libz.so.1 libz.so
    # Fix libonig
    cp -a /usr/lib/x86_64-linux-gnu/libonig.so.2.0.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libonig.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libonig.so.2 ${buildroot}${php55_location}/lib
    # Fix libpng
    cp -a /usr/lib/x86_64-linux-gnu/libpng12.a ${buildroot}${php55_location}/lib
    cp -a /lib/x86_64-linux-gnu/libpng12.so.0.50.0 ${buildroot}${php55_location}/lib
    ln -s libpng12.so.0.50.0 libpng12.so.0
    ln -s libpng12.so.0 libpng12.so
    ln -s libpng12.so libpng.so
    ln -s libpng12.a libpng.a
    # Fix libjpeg
    cp -a /usr/lib/x86_64-linux-gnu/libjpeg.a ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libjpeg.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libjpeg.so.62.1.0 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libjpeg.so.62 ${buildroot}${php55_location}/lib
    # Fix libwebp
    cp -a /usr/lib/x86_64-linux-gnu/libwebpdemux.so.1.0.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebp.so.5 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebp.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpmux.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebp.a ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpmux.so.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebp.so.5.0.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpdemux.so.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpmux.so.1.0.1 ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpmux.a ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpdemux.so ${buildroot}${php55_location}/lib
    cp -a /usr/lib/x86_64-linux-gnu/libwebpdemux.a ${buildroot}${php55_location}/lib
    echo "${php55_location}/lib" > ${buildroot}/etc/ld.so.conf.d/php55.conf

    cat > ${buildroot}/DEBIAN/control << EOF
Package: hws-php55
Version: 5.5.38
Section: php
Priority: optional
Architecture: amd64
Eseential: no
Depends: autoconf,patch,m4,bison,libbz2-dev,libgmp-dev,libldb-dev, \
libpam0g-dev,autoconf2.13,pkg-config,libxslt1-dev,zlib1g-dev, \
libpcre3-dev,libtool,libjpeg-dev,libpng-dev,libpspell-dev, \
libmhash-dev,libenchant-dev,libwebp-dev,libxpm-dev,libvpx-dev, \
libreadline-dev,libzip-dev,libmcrypt-dev,unixodbc-dev, \
libtidy-dev,python-dev,libonig-dev
Maintainer: Jerry Wang[1976883731@qq.com]
Description: php5.5.38 build by hws
Homepage: https://www.hws.com
EOF

    cat > ${buildroot}/DEBIAN/postinst << 'EOF'
ldconfig -v > /dev/null 2>&1
[ $? -ne 0 ] && echo "[ERROR]: ldconfig"
update-rc.d -f php55 defaults >/dev/null 2>&1
[ $? -ne 0 ] && echo "[ERROR]: update-rc.d -f php55 defaults"
/etc/init.d/php55 start
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/postinst

    cat > ${buildroot}/DEBIAN/prerm << 'EOF'
/etc/init.d/php55 stop > /dev/null 2>&1
update-rc.d -f php55 remove >/dev/null 2>&1
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/prerm

    cat > ${buildroot}/DEBIAN/postrm << 'EOF'
ldconfig -v > /dev/null 2>&1
exit 0
EOF
    chmod +x ${buildroot}/DEBIAN/postrm

    cd /tmp
    dpkg-deb -b ${buildroot} php-5.5.38-linux-amd64.deb
}

main() {
    include config
    include public
    load_config
    IsRoot
    InstallPreSetting
    debbuild_php55
}
main "$@" |tee /tmp/install.log
