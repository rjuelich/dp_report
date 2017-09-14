#!/bin/bash

study=$1
out_home=$2
sublist=$3

phx="/ncf/cnl03/PHOENIX"
csv="${phx}/GENERAL/${study}/${study}.csv"




#TODO: add sublist autogen if not specified



if [ ! -e ${out_home} ]
then
	mkdir ${out_home}
fi

if [ ! -e ${out_home} ]
then
	echo "${out_home} cannot be generated. Try doing so manually and rerun."
	exit 1
fi
	



cd ${out_home}

if [ ! $3 ]
then
	awk -F , '{print $2}' ${csv} | grep -v Subject > .sublist.txt
	sublist=".sublist.txt"
fi

for subID in `awk -F , '{print $2}' ${csv} | grep -f ${sublist}`
do
	if [ `grep ${subID} ${csv} | awk -F , '{ if (length($5)>=2) print "2"; else print "0"}'` -gt 1 ]
	then
		#bwID=`grep ${subID} ${csv} | awk -F , '{print $5}'`
		bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${subID}/phone/raw | head -1`
		mkdir ${subID} ${subID}/{phone,mri,actigraphy,info,dp_report} ${subID}/actigraphy/{raw,processed} ${subID}/phone/processed ${subID}/phone/processed/${bwID} ${subID}/mri/{struc,func,qc,processed,clin}
		
		for gen_data in `ls -1 ${phx}/GENERAL/${study}/${subID}/phone/raw/${bwID}`
		do
			if [ ${gen_data} = "surveyAnswers" ]
			then
				mkdir ${subID}/phone/processed/${bwID}/${gen_data}
			
				for survey in `ls -1 ${phx}/GENERAL/${study}/${subID}/phone/raw/${bwID}/${gen_data}`
				do	
					mkdir ${subID}/phone/processed/${bwID}/${gen_data}/${survey}
				done
			else
				mkdir ${subID}/phone/processed/${bwID}/${gen_data}
			fi
		done

		for pro_data in `ls -1 ${phx}/PROTECTED/${study}/${subID}/phone/raw/${bwID}`
		do
			mkdir ${subID}/phone/processed/${bwID}/${pro_data}
		done

	else
		echo "${subID} does not have a BEIWE_ID listed in the ${phx}/GENERAL/${study}/${study}.csv file. Cannot be run"
		exit 1
	fi
done

if [ ! -e ${out_home}/.${study}_demos.csv ]
then
	echo "WARNING:"
	echo "${out_home}/.${study}_demos.csv does not exist."
	echo "That file will need to be created for header to populate properly."
	echo "At minimum, the file should contain the following fields exactly as shown: subID,age,gender,race,diagnosis"
	echo ""
	echo ""
	echo ""
fi

if [ ! -e ~/.${study}_auth ]
then
	echo "WARNING:"
	echo "~/.${study}_auth file does not exist"
	echo "~/.${study}_auth must exist for protected datatype processing to complete."
	echo "~/.${study}_auth should be a single line containing the ${study} study decrypt passcode"
	echo "Only `whoami` should have read perms for the file, obviously."

	printf "Would you like to create the ~/.${study}_auth file now? y/n: "
	read answer

	if [ ${answer} = "y" ]
	then
		printf "Please enter decrypt pass and press enter:"
		read pass
		echo ${pass} > ~/.${study}_auth
		chmod 700 ~/.${study}_auth
	else
		echo "OK, please be sure to create later."
	fi
fi

echo "${out_home} has been configured as the output directory for the ${study} study DP reports"
echo "Please take actions to address any warning generated during config."

exit 0
