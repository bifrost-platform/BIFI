#!/bin/bash

SOURCE_DIR=/github/workspace/contracts
OUTPUT_PATH=/github/workspace/output
TRUFFLE_KIT=/github/workspace/contracts/truffleKit
ERROR=false

cd $SOURCE_DIR

solidityCompile() {
    solc --optimize $1 --allow-paths $SOURCE_DIR &> OUTPUT_PATH
    grep -A4 'Error: .*$' OUTPUT_PATH >> errors

    echo $1 >> codesize
    solc --optimize --combined-json bin-runtime $1 --allow-paths $SOURCE_DIR > $1".json"
    CODESIZE=$(cat $1.json | jq '.contracts[] | select(."bin-runtime" != "") | ."bin-runtime"' | wc -m)
    CODESIZE=`expr $CODESIZE / 2`
    PERCENT=`expr $CODESIZE \* 100 / 24576`
    echo $PERCENT\% >> codesize
    if [ $CODESIZE -gt 24576 ] ; then
            ERROR=true
    fi

    echo "<br>" >> codesize
}

shopt -s nullglob dotglob

for pathName in $(find $SOURCE_DIR -name '*.sol'); do
  if echo "$pathName" | grep -q "$TRUFFLE_KIT"; then
    continue
  else
    solidityCompile $pathName
  fi
done

FILESIZE=$(wc -c "errors" | awk '{print $1}')

if [ $FILESIZE -gt 0 ];then
    cat errors
    exit 1;
fi
if [ $ERROR = true ];then
    echo "code size error"
    cat codesize
    exit 1;
fi

echo "Solidity Compile Done"
