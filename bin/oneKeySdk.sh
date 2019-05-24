#! /bin/bash

#添加权限
chmod 775 *

check_error() {
        if [ $? -ne 0 ]
        then
                echo "Error:run [$1] failed!"
                exit 1
        fi
}

#添加依赖库
#apt-get install nvme-cli dmidecode sg3-utils

# 删除旧的license
#rm -f privateKey.pem pubKey.pem r.txt license.txt

#生成公钥私钥
if [ ! -f ./privateKey.pem ]
then
    openssl genrsa -out privateKey.pem 1024
    check_error "openssl genrsa -out privateKey.pem 1024"

    openssl rsa -in privateKey.pem -pubout -out pubKey.pem
    check_error "openssl rsa -in privateKey.pem -pubout -out pubKey.pem"
else
   read  -p "检测到rsa密钥已经存在[privateKey.pem,publickey.pem],若更新算法时请勿重新生成密钥,否则已有授权将失效！确认要更新密钥吗? [Y/N]?" answer
   case $answer in
   Y | y)
      echo "updating rsa screct...";
      openssl genrsa -out privateKey.pem 1024
      check_error "openssl genrsa -out privateKey.pem 1024"

      openssl rsa -in privateKey.pem -pubout -out pubKey.pem
      check_error "openssl rsa -in privateKey.pem -pubout -out pubKey.pem"
   ;;
   N | n)
      echo "publickey is newest!"
   ;;
   *)
      echo "publickey is newest"
   ;;

   esac
fi

#将公钥转换为c字符串
./ev_codec -c pubKey.pem ../src/pubKey.hpp && sed -i "s|key|pubKey|g" ../src/pubKey.hpp
check_error "./ev_codec -c pubKey.pem ../src/pubKey.hpp"

#生成摘要
./ev_license -r r.txt
check_error "./ev_license -r r.txt"

#生成license
./ev_license -l privateKey.pem r.txt license.txt
check_error "./ev_license -l privateKey.pem r.txt license.txt"

#进入src路径，编译源码
cd /usr/local/ev_sdk/src/
if [ ! -d ./build ]
    then
        mkdir build
fi
cd build && cmake .. && make clean && make -j8
check_error "make -j8"

cd /usr/local/ev_sdk/test/
make clean
make -j
check_error "make -j"

echo "finished."

