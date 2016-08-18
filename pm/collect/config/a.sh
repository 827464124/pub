#!/bin/bash

IFS="|"

while read a b c d e f g h i
do
        echo "a=$a"
        echo "b=$b"
        echo "c=$c"
        echo "d=$e"
        echo "e=$e"
        echo "f=$f"
        echo "g=$g"
        echo "h=$h"
        echo "i=$i"
	echo "-------------------------------"
done < $1
