#!/system/bin/sh

sel="$(smc pick -f)";

echo -E X"${sel}"X

if [ -e "$sel" ]; 
	then echo exists; 
	else echo not exists;
fi

sleep 3

sel="$(smc pick -A /storage/emulated/legacy/ )"

OIFS=$IFS

IFS=""

for f in $sel ; 
do
 echo -E f=X"$f"X
 
 realname="$(echo -e "$f")"
 
 echo -E selected X"$realname"X
 
 echo
 
 if [ -e "$realname" ]; 
 then 
 	echo exists; 
 	else 
 		echo not exists;
 fi;
 
done

IFS=$OIFS