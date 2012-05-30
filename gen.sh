#!/bin/sh

rm cscope* 

find . -name "*.h" -o -name "*.lua" -o -name "*.cc" > cscope.files
cscope -bkq -i cscope.files

rm tags

ctags `find . -name "*.h" -o -name "*.lua"` -a
