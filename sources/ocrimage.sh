#!/bin/bash

set -e

tmpdir=/tmp/seed
lockfile=$tmpdir/`basename $0`.lock

# skip directories
if [ -d "$1" ]; then
  exit 0
fi

mkdir -p $tmpdir

# 创建锁文件以防止并发执行
while [ -e "$lockfile" ];
do
    sleep 1
done

if ( set -o noclobber; echo "locked" > "$lockfile" ) 2> /dev/null; then
  trap 'rm -f "$lockfile"; exit $?'  INT TERM KILL EXIT
else
  exit 1
fi

# 处理图像文件的OCR
echo "处理图像OCR: $1"

# 使用tesseract进行OCR处理，支持德语和英语
tesseract "$1" - -l deu+eng --psm 3 --oem 3 2> /dev/null | tr '\n' ' '

# 清理临时文件
rm -f "$lockfile"