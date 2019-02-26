#!/bin/bash
for f in *.dot
do
	fullname="$f"
	realname=${fullname%.*}
	foo="$realname-plain.txt"
	dot $fullname -Tplain -o $foo
	foo="$realname.pdf"
	dot $fullname -Tpdf -o $foo
done