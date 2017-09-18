#!/bin/bash

##########################################################

dp_home="__install_dir__"

#########################################################

if [ ! -e CBARS ]
then
	mkdir CBARS
fi

rm CBARS/*

cp ${dp_home}/ICONS/*png CBARS/


wff=`identify *png | awk '{print $3, $1}' | sed 's/\([0-9]\)x\([0-9]\)/\1 \2/g' | sort -n | awk '{print $3}' | sed 's/.png\(.*\)/.png/g' | tail -1`

wf=`identify ${wff} | awk '{print $3}' | awk -F x '{print $1}'`

hsa=`identify *gps_disthome_array_scale0to10.png | awk '{print $3}' | awk -F x '{print $2}'`

for datatype in  surveyAnswers1 surveyAnswers2 gps_disthome accel voice callLog textsLog ACT LIGHT clin qc func
do
	if [ `ls -1 | grep ${datatype} | grep -c png` -ge 1 ]
	then		
		i=`ls -1 | grep ${datatype} | egrep -v 'mean|parse'`
		wo=`identify ${i} | awk '{print $3}' | awk -F x '{print $1}'`
		ws=`expr $wf - $wo`
		h=`identify ${i} | awk '{print $3}' | awk -F x '{print $2}'`

		if [ ${datatype} = "voice" ]
		then
			h=${hsa}
		fi


		havg=`identify *png | awk '{print $3}' | awk -F x '{sum+= $2}END{print int(sum/NR)}'`

		if [ `echo ${h} ${havg} | awk '{ if (($1/$2)>=1.5) print "2"; else print "0"}'` -gt 1 ]
		then
			h=`echo ${havg} | awk '{print $1*1.5}'`
		fi

		hbar=`identify CBARS/${datatype}_bar.png | awk '{print $3}' | awk -F x '{print $2}'`
		hbarz=`echo ${h} ${hbar} | awk '{ print int((($1/$2)*100)/2)}'`

		if [ ${datatype} = "clin" ] || [ ${datatype} = "qc" ]
		then
			#hbarz=`echo ${h} ${hbar} | awk '{ print int((($1/$2)*100)/1)}'`
			convert CBARS/${datatype}_bar.png -resize x${h} barx.png
		else
			convert CBARS/${datatype}_bar.png -resize ${hbarz}% barx.png
		fi

		wbar=`identify barx.png | awk '{print $3}' | awk -F x '{print $1}'`
		posbx=`expr $wf - ${wbar}`
		convert ${i} -background white -fill white -gravity northeast -splice ${ws}x0 ${i}
		convert ${i} -background white -fill white -gravity west barx.png -geometry +${posbx}+0 -composite ${i}

	else
		echo "${datatype} not currently available"
	fi
done

for i in `ls -1 | egrep mean`
do
	wo=`identify ${i} | awk '{print $3}' | awk -F x '{print $1}'`
	ws=`expr $wf - $wo`

done

hf=`identify *png | egrep -v 'barx|dpreport_logo|parse' | awk '{print $3}' | awk -F x '{sum+=$2}END{print sum}'`

if [ `echo ${wf} ${hf} | awk '{ if (($1/$2)<=0.85) print "0"; else print "2"}'` -lt 1 ]
then
	wfb=`echo ${hf} | awk '{print int($1*0.85)}'`
	wfs=`expr $wfb - $wf`
	
	for png in `ls -1 | egrep -v 'barx|dpreport_logo|parse|CBARS'`
	do
		convert ${png} -background white -fill white -gravity northeast -splice ${wfs}x0 ${png}
	done
fi

exit 0
