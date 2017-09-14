#!/bin/bash
###########################################################
 
dp_home="__install_dir__" 

#########################################################
#	dp_info.sh:	Pull info from various info files to populate Participant Info table
#
#		Data from:    	beiwe/identifers.csv  
#				study.csv   
#				study_demos.csv
#

study=$1
subID=$2
study_dir=$3

if [ ! $4 ]
then
	end_d=`date +%F`
else
	end_d=$4
fi
phx="/ncf/cnl03/PHOENIX/GENERAL"
scripts_dir="${dp_home}/commons"
dp_modules="${dp_home}/MODULES"

html_dir="${dp_home}/HTML_TEMPLATES"

start_d=`grep ${subID} ${phx}/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${subID}/phone/raw | head -1`

outdir="${study_dir}/${subID}/dp_report/HTML"
outfile=${outdir}/${subID}_info.html

if [ ! -e ${outdir} ]
then
	mkdir ${outdir}
fi

cp ${html_dir}/info_template.html $outfile

info_home="${phx}/${study}/${subID}/phone/raw/${bwID}/identifiers"
info_file="`ls -1 ${info_home} | tail -1`"  # Grabs only the newest BW identifier file

# Handles cases of subject-specific files
for col in device_os os_version manufacturer model beiwe_version
do
	val=`awk -F , -f ${scripts_dir}/readcsvhdr_info.awk c1=$col ${info_home}/"${info_file}"`
	sed -i s/_${col}_/"${val}"/g $outfile
done

# Handles cases of multiple subjects in same file
for demo in race age gender diagnosis
do
	val=`awk -F , -f ${scripts_dir}/readcsvhdr.awk c1=mri_id c2=${demo} ${study_dir}/.${study}_demos.csv | grep ${subID} | awk -F , '{print $2}'`
	sed -i s/_${demo}_/"${val}"/g ${outdir}/${subID}_info.html
done

# Handles case of pulling the variable from memory
sed -i s/_bwID_/${bwID}/g ${outdir}/${subID}_info.html
sed -i s/_subID_/${subID}/g ${outdir}/${subID}_info.html
sed -i s/_study_/${study}/g ${outdir}/${subID}_info.html

exit 0
