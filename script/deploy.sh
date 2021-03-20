#!/bin/sh -e

# 解决对命令的执行结果重复判断问题
shopt -s expand_aliases

alias CHECKRETURN='{
    ret=${?}
    if [ ${ret} -ne 0 ]; then
       read errmsg
       echo ${errmsg}
       return ${ret}
    fi
}<<<'

# app名称
APP_NAME=$1
# release发布单参数
RELEASE=$2
# env环境参数
ENV=$3
# app压缩包名参数
ZIP_PACKAGE_NAME=$4
# app压缩包的网络下载地址
ZIP_PACKAGE_URL=$5
# port服务端口参数
PORT=$6
# action服务启停及部署参数
ACTION=$7

# app可执行文件名或包名
PACKAGE_NAME="rob-reviews-1.0.jar"
# app部署根目录
APP_ROOT_HOME="/app"
# app软件包保存根目录
LOCAL_ROOT_STORE="/var/ops"

# 由前面的变量组合起来的目录
# app安装路径
APP_HOME="$APP_ROOT_HOME/$APP_NAME"
# app当前运行版本的压缩包保存路径
LOCAL_STORE="$LOCAL_ROOT_STORE/$APP_NAME/current"
# app上一个版本的压缩包保存路径，用于一次性回滚
LOCAL_BACK="$LOCAL_ROOT_STORE/$APP_NAME/backup"

# 获取应用进程PID，供后面的函数判断之用 
PID=$(ps aux |grep "${PACKAGE_NAME}"|grep -v "salt"|grep -v "grep"|awk '{print $2}')
CHECKRETURN "ERROR: 获取应用进程ID失败"
echo $PID


# 先建立相关目录，备份上次部署的软件包，再从构件服务器上获取软件包，保存到指定目录。
# 只支持一次回滚，想回滚多次，最好再重新部署之前的发布单
fetch() {
    # 判断之前是否存在相关目录，如果没有，再新建
    if [ ! -d $APP_HOME  ];then
        mkdir -p $APP_HOME
		CHECKRETURN "ERROR: 建立$APP_HOME目录失败"
    fi
    if [ ! -d $LOCAL_STORE  ];then
        mkdir -p $LOCAL_STORE
		CHECKRETURN "ERROR:  建立$LOCAL_STORE目录失败"
    fi
    if [ ! -d $LOCAL_BACK  ];then
        mkdir -p $LOCAL_BACK
		CHECKRETURN "ERROR:  建立$LOCAL_BACK目录失败"
    fi
    # 删除上上次备份的软件包(无多次回滚)
    if [ -f "$LOCAL_BACK/$ZIP_PACKAGE_NAME" ];then
        mv $LOCAL_BACK/$ZIP_PACKAGE_NAME /tmp/
		CHECKRETURN "ERROR: 移动上次备份的软件包失败"
    fi
    # 备份上次的软件包
    if [ -f "$LOCAL_STORE/$ZIP_PACKAGE_NAME" ];then
        mv $LOCAL_STORE/$ZIP_PACKAGE_NAME $LOCAL_BACK/$ZIP_PACKAGE_NAME
		CHECKRETURN "ERROR: 备份上次的软件包失败"
    fi
    # 获取本次的部署包
    wget -q -P $LOCAL_STORE $ZIP_PACKAGE_URL
	CHECKRETURN "ERROR: 获取本次的部署包失败"

    echo "APP_NAME: $APP_NAME prepare success." 
}

# 回滚，从BACKUP目录解压恢复
rollback() {
    rm -rf $APP_HOME/*
	CHECKRETURN "ERROR: 删除当前APP应用的目录文件失败"
    tar -xzvf $LOCAL_BACK/$ZIP_PACKAGE_NAME -C $APP_HOME
	CHECKRETURN "ERROR: 从$LOCAL_BACK回滚目录中解决部署包失败"
    echo "APP_NAME: $APP_NAME rollback success."
}
 
# 清除目录已有文件，将CURRENT解压到运行目录
deploy() {
    rm -rf $APP_HOME/*
	CHECKRETURN "ERROR: 删除当前APP应用的目录文件失败"
    tar -xzf $LOCAL_STORE/$ZIP_PACKAGE_NAME -C $APP_HOME
	CHECKRETURN "ERROR: 从$LOCAL_STORE下载目录中解决部署包失败"
	# 此处还可以根据传过来的$ENV,$PORT,$RELEASE等参数，作一个性化的部署及配置处理
	# 甚至可以传更多的参数，进行增量全量，软件包或配置的个别部署处理
    echo "APP_NAME: $APP_NAME deploy success."
} 
#启动应用，传递了port和env参数
start() {
	# 判断是否存APP还在运行，如果运行，则不启动，报错并返回
    if [ -n "$PID" ]; then
        echo "Project: $APP_NAME is running, kill first or restart, failure start."
        return 1
    fi
    
    #此处为真正启动命令(不同的应用，必须重写此处，不能统一处理)
	cd "$APP_HOME"
        nohup java -Djava.security.egd=file:/dev/./urandom -jar target/${PACKAGE_NAME} --server.port=${PORT}  >/dev/null 2>&1 &
	CHECKRETURN "ERROR: 启动APP应用的命令失败"
	sleep 2
	echo "APP_NAME:  $APP_NAME is start success . "
}
   
stop() {
	if [ -n "$PID" ]; then
		# 这里可以加入程序的自然停止命令，或是拉出服务集群，实现优雅停止命令
		# 但如果一个程序能直接被KILL -9，但依然能保证数据一致性，服务不受影响，也是撸棒性表现，自己权衡
		kill -9 $PID
		CHECKRETURN "ERROR: 杀死APP应用的命令失败"
		sleep 2
	fi
	echo "APP_NAME: $APP_NAME is success stop."
}
   
start_status() {
    if [ -n "$PID" ]; then
        echo "APP_NAME: $APP_NAME is success on running."
    else
        echo "APP_NAME: $APP_NAME is failure on running."
    fi
}

stop_status() {
    if [ -n "$PID" ]; then
        echo "APP_NAME: $APP_NAME is failure on stop."
    else
        echo "APP_NAME: $APP_NAME is success on stop."
    fi
}

health_check() {
	# 此处可以加一些进程是否存在，端口是否开启，或是访问指定的URL是否存在的功能
	echo "APP_NAME: $APP_NAME is success health."
}
   
case "$ACTION" in
    fetch)
        fetch
        ;;
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    stop_status)
        stop_status
        ;;
	start_status)
        start_status
        ;;
	health_check)
		health_check
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo $"Usage: $0 {7 args}"
esac
