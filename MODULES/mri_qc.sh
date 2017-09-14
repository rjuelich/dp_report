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
moduledir="${script_dir}/DP_HOME/MODULES"
out_sub="${out_home}/${sub}/mri"
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`
rawdir="${phx}/GENERAL/${study}/${sub}/mri/raw"
datestr=`date +%y%m%d_%H:%M`
start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`
days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1.9)}'`

####################################################################################################

cd ${out_sub}

if [ ! -e qc ]
then
	mkdir qc
else
	rm qc/*
fi

for i in `echo ${days_to_plot} | awk '{for (v=1; v<=$1; v++) print v}'`
do 
	sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`
	sdayid=`grep ${sub} ${out_home}/.${study}_scales.csv | grep ${sday} | awk -F , '{print $3}'`	

	if [ `ls -1 ${out_sub}/processed | grep -c ${sday}_` -ge 2 ] && [ -e ${out_sub}/processed/${sdayid}/qc/INDIV_MAPS ]
	then
		snr1=`grep SNR1 ${out_sub}/processed/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print 100-$4}'`
		snr2=`grep SNR2 ${out_sub}/processed/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print 100-$4}'`
		R=`grep Corr ${out_sub}/processed/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		a=`grep Slope ${out_sub}/processed/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		b=`grep Intercept ${out_sub}/processed/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		date -d "${start_d} UTC ${i} days" +%F,${i},${snr1},${snr2},${R},${a},${b}
	else
		date -d "${start_d} UTC ${i} days" +%F,${i},NaN,NaN,NaN,NaN,NaN
	fi
done | pcut -cs , -cd , -c 3-max | awk -F , 'BEGIN{printf "%s,%s,%s,%s,%s\n", "SNR-1", "SNR-2", "Correlation", "Slope", "Intercept"}{OFS=","; print $1, $2, $3, $4, $5}' > ${out_sub}/qc/${sub}_${days_to_plot}days_qc_array.csv

cd ${out_sub}/qc

gplot.sh ${sub}_${days_to_plot}days_qc_array.csv 0 100 "BOLD QC" ${sun1}

png=PNG/`ls -1 | grep .png$ | grep -v parse`

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.qc.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> MRI QC Measures</h5></td></tr>' >> ${sub}.qc.html

echo '<tr><td> <img src="'${png}'" alt="qc" align=left width="1200px"></td></tr>' >> ${sub}.qc.html

echo '</table>' >> ${sub}.qc.html

cd ..

