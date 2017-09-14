#!/bin/bash
##########################################################

dp_home="__install_dir__"

#########################################################
#   DP HTML WRAPPER:
#
#	1. Creates HTML folder for participant
#	2. Copies all HTML files created during processing (find under "phone", "actigraphy" and "mri")
#	3. Uses regular naming congvention to figure out which headers to use
#	4. Adds available HTML to appropriate sections: INFO, STUDY VISIT (clin, mri), ACTIVE (surveys, voice), PASSIVE (beiwe, actigraphy)

#  "info" should become its own datatype
#  find should look across all available folders

if [ $# -lt 1 ]
then
	echo "Usage:  ...."
fi


study=$1
subID=$2
study_dir=$3  #study_dir is the main study folder

if [ -e ${out_home}/.${study}_end_dates ] && [ `grep -c ${sub} ${out_home}/.${study}_end_dates` -ge 1 ]
then
	end_d=`grep ${sub} ${out_home}/.${study}_end_dates | awk '{print $2}'`
else
	end_d=`date +%F`
fi



gentime=`date +%c | sed 's/ /_/g'`
phx="/ncf/cnl03/PHOENIX/GENERAL"
dp_modules="${dp_home}/MODULES"

html_dir="${dp_home}/HTML_TEMPLATES"
html_css="${html_dir}/DPreport.css"

start_d=`grep ${subID} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${subID}/phone/raw | head -1`
outdir="${study_dir}/${subID}/dp_report"
outfile=${outdir}/${subID}_DPreport.html

#  1. Create directories
if [ ! -e $outdir ]
then
	mkdir $outdir 
else 
	rm ${outdir}/*{html,pdf}
fi

if [ ! -e ${outdir}/HTML ]
then
	mkdir ${outdir}/{HTML,PDF,PNG}
else
	rm ${outdir}/HTML/* ${outdir}/PNG/*
fi

# 2. Go to output dir and sweep for files
cd $outdir
touch $outfile

cp ${html_dir}/dpreport_logo.png ./PNG
cp ${html_dir}/w3.css ./

for datatype in phone actigraphy mri
do
	if [ -e ${study_dir}/${subID}/${datatype} ]
	then
		find ${study_dir}/${subID}/${datatype} -name "*.html" -exec cp '{}' ./HTML/ \;
		find ${study_dir}/${subID}/${datatype} -name "*.png" -exec cp '{}' ./PNG \;
	fi
done

cd ./PNG/
${dp_home}/dp_png_buffer.sh  # Adds the legend and any additional buffer to each PNG


cd ${outdir}/HTML

${dp_modules}/dp_info.sh ${study} ${subID} ${study_dir}  

#  Now we will create the DPreport HTML file and begin appending sections
#
#  Sections to Append for REPORT:   DPreport
#  1.  dp_info
#  2.  ...

# First open the HTML file and drop in CSS
cat ${html_dir}/body_template_top.html ${html_css} >> $outfile

# Next open the body section
echo '<body style="font-size:16px; font-family:Helvetica; font-weight:800;">' >> $outfile

# Next drop in info section
cat ${subID}_info.html >> $outfile

#Checking for Study Visit measures
if [ `ls -1 | egrep -c 'clin|func|qc'` -ge 1 ]
then
	${dp_modules}/dp_headline.sh "Study Visit Measures" >> $outfile 

	for datatype in clin func qc
	do
		if [ -e ${subID}.${datatype}.html ]
		then
			cat ${subID}.${datatype}.html >> $outfile
		fi
	done
fi

# Checking for Active datatypes
if [ -e ${subID}.voiceRecording.html ] || [ -e ${subID}.surveyAnswers.html ]
then
	${dp_modules}/dp_headline.sh "Active Measures" >> $outfile 

	for datatype in surveyAnswers1 surveyAnswers2 voiceRecording 
	do
		if [ -e ${subID}.${datatype}.html ]
		then
			cat ${subID}.${datatype}.html >> $outfile
		fi
	done
fi

# Checking for Passive datatypes
if [ `ls -1 | egrep -c 'call|gps|accel|actigraphy'` -ge 1 ]
then
	${dp_modules}/dp_headline.sh "Passive Measures" >> $outfile 

	for datatype in gps accel actigraphy callLog textsLog
	do
		if [ -e ${subID}.${datatype}.html ]
		then
			cat ${subID}.${datatype}.html >> $outfile
		fi
	done
fi

# Finally close the body section of the HTML
echo '</body>' >> $outfile

sed -i 's/_gentime_/'${gentime}'/g' ${outfile}

#   This will convert the HTML report into a PDF
${dp_home}/makepdf $outfile ${outdir}/PNG

exit 0
