#!/bin/bash

study=$1
sub=$2
bwID=$3
out_home=$4
start_d=$5
end_d=$6

if [ ! $6 ]
then
	end_d=`date +%F`
fi

phx="/ncf/cnl03/PHOENIX"
script_dir="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS"
moduledir="${script_dir}/dp_modules"
out_sub="${out_home}/${sub}/mri"
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`
rawdir="${phx}/GENERAL/${study}/${sub}/mri/raw"
datestr=`date +%y%m%d_%H:%M`
start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`
days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1.9)}'`


#######################################################################################

cd ${out_sub}


if [ ! -e clin ]
then
	mkdir clin
else
	rm clin/*
fi

head -1 ${out_home}/.${study}_scales.csv | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 > clin/clin_array.csv
cp clin/clin_array.csv clin/clin_array_sparse.csv

for i in `echo ${days_to_plot} | awk '{for (v=1; v<=$1; v++) print v}'`
do
	sday=`date -d "${start_d} UTC ${i} days" +%F`
	#sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`

	#if [ `ls -1 ${out_sub}/processed | grep -c ${sday}_` -ge 2 ]
	#then
	#	sdayid=`ls -1 ${out_sub}/processed | grep ${sday} | head -1`
	#else
	#	sdayid=blah
	#fi

	#echo ${sdayid}

	sdayid=${sday}

	if [ `grep -c ${sdayid} ${out_home}/.${study}_scales.csv | awk '{print $1}'` = 1 ]
	then
		grep ${sdayid} ${out_home}/.${study}_scales.csv | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 >> ${out_sub}/clin/clin_array.csv
		grep ${sdayid} ${out_home}/.${study}_scales.csv | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 >> ${out_sub}/clin/clin_array_sparse.csv
	else
		echo "NaN,NaN,NaN,Nan,NaN" >> ${out_sub}/clin/clin_array.csv
	fi
done

cd ${out_sub}/clin

#### NEW
mv clin_array.csv array.tmp

mymrs=`awk -F , '{print $1}' ${out_home}/.${study}_scale_means.csv`
mmadrs=`awk -F , '{print $2}' ${out_home}/.${study}_scale_means.csv`
mpanssp=`awk -F , '{print $3}' ${out_home}/.${study}_scale_means.csv`
mpanssn=`awk -F , '{print $4}' ${out_home}/.${study}_scale_means.csv`
mpanssg=`awk -F , '{print $5}' ${out_home}/.${study}_scale_means.csv`
mpansst=`awk -F , '{print $6}' ${out_home}/.${study}_scale_means.csv`
mmcas=`awk -F , '{print $7}' ${out_home}/.${study}_scale_means.csv`


symrs=`awk -F , '{print $1}' ${out_home}/.${study}_scale_stds.csv`
smadrs=`awk -F , '{print $2}' ${out_home}/.${study}_scale_stds.csv`
spanssp=`awk -F , '{print $3}' ${out_home}/.${study}_scale_stds.csv`
spanssn=`awk -F , '{print $4}' ${out_home}/.${study}_scale_stds.csv`
spanssg=`awk -F , '{print $5}' ${out_home}/.${study}_scale_stds.csv`
spansst=`awk -F , '{print $6}' ${out_home}/.${study}_scale_stds.csv`
smcas=`awk -F , '{print $7}' ${out_home}/.${study}_scale_stds.csv`

grep -v panss array.tmp | awk -F , 'BEGIN{print "ymrs,madrs,panss+,panss-,mcas"}{OFS=","; if ($1!="NaN") print ($1-"'${mymrs}'")/"'$symrs'", ($2-"'$mmadrs'")/"'$smadrs'", ($3-"'$mpanssp'")/"'$spanssp'", ($4-"'$mpanssn'")/"'$spanssn'", -1*(($5-"'$mmcas'")/"'$smcas'"); else print $1, $2, $3, $4, $5}' > clin_array.csv


mv clin_array_sparse.csv sparse.tmp


grep -v ymrs sparse.tmp | awk -F , 'BEGIN{print "ymrs,madrs,panss+,panss-,mcas"}{OFS=","; if ($1!="NaN") print ($1-"'${mymrs}'")/"'$symrs'", ($2-"'$mmadrs'")/"'$smadrs'", ($3-"'$mpanssp'")/"'$spanssp'", ($4-"'$mpanssn'")/"'$spanssn'", -1*(($5-"'$mmcas'")/"'$smcas'"); else print $1, $2, $3, $4, $5}' > clin_array_sparse.csv

####
gplot.sh clin_array.csv -2 2 "Clinical Scales" ${sun1}
gplot.sh clin_array_sparse.csv -2 2 "Clinical Scales" ${sun1}


png=PNG/`ls -1 | grep .png$ | grep -v parse`

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.clin.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;">Clinical Scales</h5></td></tr>' >> ${sub}.clin.html

echo '<tr><td> <img src="'${png}'" alt="gps" align=left width="1200px"></td></tr>' >> ${sub}.clin.html

echo '</table>' >> ${sub}.clin.html

cd ${out_home}

exit 0


