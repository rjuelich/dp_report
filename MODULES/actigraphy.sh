#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
sub=$1
days_to_plot=$2
cfg=$3
datestr=$4
sun1=$5
start_d_sec=$6


rm processed/*
for i in `cat $cfg`
do
	sed 's///g' raw/${i} | sed 's/"//g' | sed 's/ AM/AM/g' | sed 's/ PM/PM/g' > processed/`echo ${i} | sed 's/_\([1-9]\)_/_0\1_/g' | sed 's/_\([1-9]\)_/_0\1_/g'`
done

cd processed	


for i in `ls -1`
do
	x=`grep -n Activity ${i} | awk -F \: '{print $1}' | tail -1`
	y=`wc -l ${i} | awk '{print $1}'`

	lines=`echo "$x $y" | awk '{print $2-$1}'`
	
	echo ${lines}
	
	grep Activity ${i} | tail -1 | awk -F , 'NR==1{OFS=","; for (n=1; n<=NF; n++) if ($n=="Date" || $n=="Time" || $n=="Activity" || $n=="Marker" || $n=="White Light") print $n,n}' > cols.tmp

	for col in Date Time Activity Marker Light
	do
		export ${col}="`grep ${col} cols.tmp | awk -F , '{print $2}'`"
	done

	tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Date},${Time},${Activity},${Marker},${Light} | grep -v ime | awk -F , '{OFS=","; "date -d \""$1"\" +%s" | getline dt; print int(((dt-"'${start_d_sec}'")/(60*60*24))+1.5)}' > ${i}.day.tmp


	for d in `tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Time} | grep -v ime`
	do
		date -d ${d} +%k >> ${i}.hrs.tmp
	done

	tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Activity},${Light} | grep -v ight | paste -d , ${i}.day.tmp ${i}.hrs.tmp - > ${i}_array.csv

done

for i in `ls -1 | grep csv_array.csv`;
do
	cat ${i} >> ${sub}_${datestr}_samples.csv
done

sed -i 's/ //g' ${sub}_${datestr}_samples.csv

for d in `echo ${days_to_plot} | awk '{for (i=1; i<=$1; i++) print i}'`
do 
	for h in {0..23}
	do
		if [ `grep -c ^$d,$h, ${sub}_${datestr}_samples.csv | awk '{print $1}'` -ge 1 ]
		then
			cat ${sub}_${datestr}_samples.csv | grep -v NaN | awk -F , '{OFS=","; if  ($1=="'${d}'" && $2=="'${h}'") print $3}' | awk '{sum+=$1}END{print sum/NR}'
		else
			echo "NaN"
		fi
	done | paste -s -d , - >> ACT_array
done


for d in `echo ${days_to_plot} | awk '{for (i=1; i<=$1; i++) print i}'`
do 
	for h in {0..23}
	do
		if [ `grep -c ^$d,$h, ${sub}_${datestr}_samples.csv | awk '{print $1}'` -ge 1 ]
		then
			cat ${sub}_${datestr}_samples.csv | grep -v NaN | awk -F , '{OFS=","; if  ($1=="'${d}'" && $2=="'${h}'") print $4}' | awk '{sum+=$1}END{print sum/NR}'
		else
			echo "NaN"
		fi
	done | paste -s -d , - >> LIGHT_array
done


days_to_plot=`echo ${days_to_plot} | awk '{printf "%03d\n", $1}'`

cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv ACT_array > ${sub}_ACT_array.csv
cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv LIGHT_array > ${sub}_LIGHT_array.csv


if [ -e ${sub}.actigraphy.sh ]
then
	chmod 775 ${sub}.actigraphy.sh
	./${sub}.actigraphy.sh
else
	${dp_home}/commons/gplot.sh ${sub}_ACT_array.csv 0 250 "Actigraphy" ${sun1}
	${dp_home}/commons/gplot.sh ${sub}_LIGHT_array.csv 0 1000 "Light" ${sun1}
fi

n=`cat ${sub}_ACT_array.csv | grep -v -c ^NaN,.*NaN$ | awk '{print $1-1}'`
nan=`cat ${sub}_ACT_array.csv | grep -c ^NaN,.*NaN$`
hours=`expr $n + $nan`
pct=`echo "$n $nan" | awk '{printf "%d%s\n",(($1/($1+$2))*100), "\%"}'`
pngact=PNG/`ls -1 | grep .png$ | grep ACT`
pnglight=PNG/`ls -1 | grep .png$ | grep LIGHT`

secs_last=0

for file in `ls -1 ../raw`
do
	dcol=`sed s/^M//g ../raw/${file} | sed 's/"//g' | grep Date | tail -1 | awk -F , '{ for (i=1;i<=NF;i++) if ($i=="Date") print i}'`
	file_last=`tail -10 ../raw/${file} | grep -v ^$ | tail -1 | awk -F , '{print $dcol}' dcol=$dcol | sed 's/"//g'`
	n_secs=`date -d "${file_last}" +%s`

	if [ ${n_secs} -gt ${secs_last} ]
	then 
		secs_last="${n_secs}"
	fi
done

secs_now=`date +%s`

last=`echo ${secs_now} ${secs_last} | awk '{print int(($1-$2)/(3600*24))}'`

echo "${n},${pct},${last}" > ${sub}.actigraphy.info

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.actigraphy.html
echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Activity (wrist):	'${n}'/'${hours}' hours collected ('${pct}')</h5></td></tr>' >> ${sub}.actigraphy.html
echo '<tr><td> <img src="'${pngact}'" alt="act" align=left width="1200px"></td></tr>' >> ${sub}.actigraphy.html
echo '</table>' >> ${sub}.actigraphy.html

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' >> ${sub}.actigraphy.html
echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Light Exposure (wrist):	'${n}'/'${hours}' hours collected ('${pct}')</h5></td></tr>' >> ${sub}.actigraphy.html
echo '<tr><td> <img src="'${pnglight}'" alt="light" align=left width="1200px"></td></tr>' >> ${sub}.actigraphy.html
echo '</table>' >> ${sub}.actigraphy.html


rm *tmp

cd ..

exit 0
#cat 1 > ${sub}.actigraphy.pipe
