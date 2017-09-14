#!/bin/bash

study=$1
outdir=$2
sublist=$3
gentime=`date +%c | sed 's/ /_/g'`
phx="/ncf/cnl03/PHOENIX"
csv="${phx}/GENERAL/${study}/${study}.csv"

secs_now=`date +%s`

cd ${outdir}

if [ -e ${study}_DPcover.html ]
then
	rm ${outdir}/${study}_DPcover*
fi

cp /ncf/cnl/13/users/jbaker/PSF_SCRIPTS/DP_HOME/HTML_TEMPLATES/study_coverpage.html ${outdir}/${study}_DPcover.html

if [ ! $3 ]
then
	awk -F , '{print $2}' ${csv} > .sublist.txt
	sublist=".sublist.txt"
fi

subn=1

for sub in `awk -F , '{print $2}' ${csv} | grep -v ubject`
do
	bwid=`grep ${sub} ${csv} | awk -F , '{print $5}'`
	consent=`grep ${sub} ${csv} | awk -F , '{print $3}'`
	
	if [ `grep -c ${sub} ${outdir}/.${study}_end_dates` -ge 1 ]
	then
		end_date=`grep ${sub} ${outdir}/.${study}_end_dates | awk '{print $2}'`
	else
		end_date=`date +%F`
	fi
	
	consent_secs=`date -d "${consent}" +%s` 
	end_secs=`date -d "${end_date}" +%s`

	ndays=`echo "${end_secs} ${consent_secs}" | awk '{print int(($1-$2)/(60*60*24))}'`

	if [ -e ${outdir}/${sub} ]
	then
		if [ ! -e ${outdir}/${sub}/info ]
		then
			mkdir ${outdir}/${sub}/info
		else
			rm ${outdir}/${sub}/info/*
		fi
	
		cd ${outdir}/${sub}/info

		for dt in phone mri actigraphy
		do
			if [ -e ${outdir}/${sub}/${dt} ]
			then
				find ${outdir}/${sub}/${dt} -name "*.info" -exec cp '{}' ${outdir}/${sub}/info/ \;
			fi
		done

		#sed -i 's,\(/.*s\),,g' *info

		for dt in surveyAnswers1 gps accel voiceRecording actigraphy callLog
		do
			if [ ! -e ${sub}.${dt}.info ]
			then
				echo "NA" > ${sub}.${dt}.info
			fi
			
#			if [ ${dt} = "accel" ] || [ ${dt} = "callLog" ]
#			then
#				bwroot="${phx}/GENERAL/${study}/${sub}/phone/raw/${bwid}/${dt}"
#			elif [ ${dt} = "voiceRecording" ] || [ ${dt} = "gps" ]
#			then
#				bwroot="${phx}/PROTECTED/${study}/${sub}/phone/raw/${bwid}/${dt}"
#
#				if [ ${dt} = "voiceRecording" ] && [ `ls -1 ${bwroot} | tail -1 | grep -c ^d -` -ge 1 ]
#				then
#					bwroot="${bwroot}/`ls -1 ${bwroot} | tail -1`"
#				fi
#			elif [ ${dt} = "surveyAnswers1" ]
#			then
#				bwroot="${phx}/GENERAL/${study}/${sub}/phone/raw/${bwid}/surveyAnswers/`ls -1 ${phx}/GENERAL/${study}/${sub}/phone/raw/${bwid}/surveyAnswers | head -1`"
#			elif [ ${dt} = "surveyAnswers2" ]
#			then
#				bwroot="${phx}/GENERAL/${study}/${sub}/phone/raw/${bwid}/surveyAnswers/`ls -1 ${phx}/GENERAL/${study}/${sub}/phone/raw/${bwid}/surveyAnswers | tail -1`"
#			fi
#
#			last_date="`ls -l ${bwroot} | tail -1 | awk '{print $6, $7, $8}'`"
#			secs_last=`date -d "${last_date}" +%s`

			if [ `grep -c NA ${sub}.${dt}.info` -lt 1 ]
			then
				last_hours=`awk -F , '{print $3}' ${sub}.${dt}.info`
				points=`awk -F , '{print $1}' ${sub}.${dt}.info`
				pct=`awk -F , '{print $2}' ${sub}.${dt}.info`
			else
				last_hours="NA"
				points="NA"
				pct="NA"
			fi

			if [ `grep -c NA ${sub}.${dt}.info` -lt 1 ] && [ `awk -F , '{print $2}' ${sub}.${dt}.info | sed 's/%//g'` -lt 50 ]
			then
				export ${dt}="`echo '<td align=center bgcolor=#F44336>'${points}' ('${pct}')</td><td align=center bgcolor=#F44336>'${last_hours}'</td>'`"
			elif [ `grep -c NA ${sub}.${dt}.info` -lt 1 ] && [ `awk -F , '{print $2}' ${sub}.${dt}.info | sed 's/%//g'` -ge 50 ]
			then
				#export ${dt}="`echo '<td width=6.25% align=center>'``cat ${sub}.${dt}.info``echo '</td>'`<td width=6.25% align=center>${last_hours} hrs</td>"
				export ${dt}="`echo '<td align=center>'${points}' ('${pct}')</td><td align=center>'${last_hours}'</td>'`"
			else
				#export ${dt}="`echo '<td width=6.25% align=center>'``cat ${sub}.${dt}.info``echo '</td>'`<td width=6.25% align=center>${last_hours}</td>"
				export ${dt}="`echo '<td align=center>NA</td><td align=center>NA</td>'`"
			fi 

		done

		#echo '<tr width="100%"><td width="12.5%">'${sub}'</td><td width="12.5%">'${surveyAnswers1}'</td><td width="12.5%">'${surveyAnswers2}'</td><td width="12.5%">'${gps}'</td><td width="12.5%">'${accel}'</td><td width="12.5%">'${voiceRecording}'</td><td width="12.5%" align=center>'${actigraphy}'</td><td width="12.5%">'${callLog}'</td></tr>' >> ${outdir}/${study}_DPcover.html
		
		echo '<tr width="100%"><td align=center>'${subn}'</td><td align=center>'${sub}'</td><td align=center>'${ndays}'</td><td align=center>'${consent}'</td>'${surveyAnswers1}''${gps}''${accel}''${voiceRecording}''${actigraphy}''${callLog}'</tr>' >> ${outdir}/${study}_DPcover.html

		cd ${outdir}	

	fi

	subn=`expr $subn + 1`
done

echo "</table>" >> ${outdir}/${study}_DPcover.html
echo "</body>" >> ${outdir}/${study}_DPcover.html
echo "</html>" >> ${outdir}/${study}_DPcover.html

cd ${outdir}

sed -i 's/_study_/'${study}'/g' ${study}_DPcover.html
sed -i 's/_gentime_/'${gentime}'/g' ${study}_DPcover.html

wkhtmltopdf -T 1mm -R 1mm -L 1mm -B 1mm --page-width 350mm --page-height 500mm ${study}_DPcover.html ${study}_DPcover.pdf


subjs=`awk -F , '{print $2}' ${csv} | grep -v ubject | paste -s -d \  -`

pdftk ${study}_DPcover.pdf `for subj in ${subjs}; do find ${subj} -name "*DPreport.pdf"; done | paste -s -d \  -` cat output ${study}_DPreports.pdf
	

exit 0

		
	
