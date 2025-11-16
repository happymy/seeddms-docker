#!/bin/bash

set -e

tmpdir=/tmp/seed
lockfile=$tmpdir/`basename $0`
cores=2

# skip directories
if [ -d "$1" ]; then
  exit 0
fi

mkdir -p $tmpdir

while [ -e "$lockfile" ];
do
    sleep 5
done

if ( set -o noclobber; echo "locked" > "$lockfile" ) 2> /dev/null; then
  trap 'rm -f "$lockfile"; exit $?'  INT TERM KILL EXIT
else
  exit 1
fi

# 检查PDF是否包含可搜索文本
pdf_contents=`pdftotext -nopgbrk "$1" - 2>/dev/null | sed -e 's/ [a-zA-Z0-9.]\{1\} / /g' -e 's/[0-9.]//g' | tr -d '\000-\011\013-\037'`
text_length=`echo -n "$pdf_contents" | wc -c`

# 如果文本内容很少（小于50个字符），则执行OCR
if [ "$text_length" -lt 50 ]; then
  echo "执行OCR处理: $1"
  tmpfile=$tmpdir/`date +%s%N`
  
  # 使用ocrmypdf进行OCR处理，添加更多选项以提高识别质量
  ocrmypdf \
    --language deu+eng \
    --rotate-pages \
    --jobs $cores \
    --output-type pdfa \
    --skip-text-pdf \
    --clean \
    --deskew \
    --clean-final \
    "$1" "$tmpfile" 2> /dev/null
  
  # 提取OCR处理后的文本内容
  pdf_contents=`pdftotext -nopgbrk "$tmpfile" - 2>/dev/null | sed -e 's/ [a-zA-Z0-9.]\{1\} / /g' -e 's/[0-9.]//g' | tr -d '\000-\011\013-\037'`
  mv "$tmpfile" "$1"
else
  echo "PDF已包含可搜索文本，跳过OCR处理: $1"
fi

echo "$pdf_contents"