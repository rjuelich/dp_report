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

for i in func
do
	if [ ! -e ${out_sub}/${i} ]
	then
		mkdir ${out_sub}/${i}
	else
		rm ${out_sub}/${i}/*
	fi
done

tac ${script_dir}/PSF_17net_TABLES/netnames | paste -s -d , - > ${out_sub}/func/${sub}_func.csv

cp ${out_sub}/func/${sub}_func.csv ${out_sub}/func/${sub}_funcSparse.csv

for i in `echo ${days_to_plot} | awk '{for (v=1; v<$1; v++) print v}'`
do
	sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`
	
	if [ `ls -1 ${rawdir} | grep -c ${sday}_` -ge 1 ]
	then
		sdayid=`ls -1 ${rawdir} | grep ${sday} | head -1`
	else
		sdayid=blah
	fi

	if [ -e ${out_sub}/processed/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt ]
	then
		cat ${out_sub}/processed/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_func.csv
		cat ${out_sub}/processed/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_funcSparse.csv
	else
		echo "NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN" >> ${out_sub}/func/${sub}_func.csv
	fi
done

cd ${out_sub}/func

gplot.sh ${sub}_func.csv 0 100 "17-Network FC Percentiles" ${sun1}
gplot.sh ${sub}_funcSparse.csv 0 100 "17-Network FC Percentiles" ${sun1}

png=PNG/`ls -1 | grep .png$ | grep -v parse`

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.func.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Within-Network functional connectivity</h5></td></tr>' >> ${sub}.func.html

echo '<tr><td> <img src="'${png}'" alt="funcmri" align=left width="1200px"></td></tr>' >> ${sub}.func.html

echo '</table>' >> ${sub}.func.html

cd ..
	
