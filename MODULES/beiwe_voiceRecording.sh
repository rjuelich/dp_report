#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
##########################################################
#
#  FOLLOWING SECTION SHOULD BE FIXED FOR ALL DATA TYPES
#
#########################################################

sub=$1
beiweroot=$2
start_d=$3
end_d=$4
study=$5

####################################################################################
#
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#  1.  FIRST DECIDE ON SUFFIX, Y-AXIS VALUE FILE
#  2.  EITHER COPY FROM RAW OR UNLOCK FOR ENCYRYPTED FILES
#
###################################################################################

echo ""
echo "**************************"
echo " Beiwe Audio converter"
echo "**************************"
echo ""
echo "Attempting to unlock encrypted Audio Files for subject $sub " 

suffix="beiwe_voice"
suffix="beiwe_audio_env"
rawpath=${beiweroot}
array_y_labels="${dp_home}/HTML_TEMPLATES/timeheaders_11m_by10s.csv"
mean_label="Audio Diary Duration"
module load matlab/R2012b-ncf
module load ffmpeg/2.7.2-fasrc01

python ${dp_home}/commons/beiwe_unlocker.py -p ${rawpath} -s ${study}

for i in `ls -1 ${rawpath}`
do
	if [ -e ${rawpath}/${i} ]
	then
		rp="${rawpath}/${i}"
		python ${dp_home}/commons/beiwe_unlocker.py -p ${rp} -s ${study}
	fi
done


##########################################################
#
#  FOLLOWING SECTION SHOULD BE FIXED FOR ALL DATA TYPES
#
#########################################################

rename " " _ * 
rename mp4.lock mp4 * 
rename wav.lock wav * 

start_d_sec=`date -d $start_d +%s`

# Get end day in sec
if [ ! $4 ]
then
	end_d_sec=`date +%s`
else
	end_d_sec=`date -d $end_d +%s`
fi

# Grab day of week for first day of data
dow_D1=`date -d "$start_d" "+%w"`
sun1=`find_sunday ${dow_D1}`

# Compute number of days to plot based on start and end date
days_to_plot=`echo $start_d_sec $end_d_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`

# Set up output variables
outsamples=${sub}_${suffix}_samples.csv
meanarray=${sub}_${suffix}_mean.csv
outarray=${sub}_${suffix}_array.csv

if [ -e $outarray ]
then
	rm -f $outarray $meanarray
fi

# Start arrays with what will become Y-Axis labels
echo $mean_label > $meanarray

####################################################################################
#
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#
###################################################################################

# Cycle through days and hours to populate [Day X Hour] array of values with missing filled in

echo ""
echo "Converting raw MP4 audio to volume envelope"

printf "Day "
for file in `ls *.{mp4,wav}`
do
	dater=`echo $file | awk -F '_' '{print $1}'`
	date_sec=`date -d $dater +%s`
	dos=`echo $start_d_sec $date_sec | awk '{sec=$2-$1; printf("%03d\n", int((sec/60/60/24)+0.99)+1)}' CONSENT=$start_d_sec`
	wav="${sub}_day${dos}.wav"

	# Handle the case where participant recorded two times on a day
	if [ -e $wav ]
	then
		wav="${sub}_day${dos}_2.wav"
		if [ -e $wav ]
		then
			wav="${sub}_day${dos}_3.wav"
			if [ -e $wav ]
			then
				wav="${sub}_day${dos}_4.wav"
				if [ -e $wav ]
				then
					wav="${sub}_day${dos}_5.wav"
				fi
			fi
		fi
	fi
	printf "$dos "
	ffmpeg -i $file $wav >/dev/null 2>/dev/null
	/ncf/nrg/sw/apps/matlab/R2012b/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "beiwe_audio_env('$wav');quit()" >/dev/null 2>/dev/null

	ffprobe $wav 2>&1 | grep Duration | awk '{print $2}' | sed -e '/,$/s///' | awk -F ':' '{print $1*3600+$2*60+$3}' > ${sub}_day${dos}_dur.txt
done

####################################################################
#
#  FOLLOWING SECTION SHOULD REMAIN MOSTLY FIXED FOR ALL DATA TYPES
#
###################################################################

echo ""
echo ""
echo "Compiling into $dos day array of volume envelopes"
printf "day "
d=1
while [ $d -le ${days_to_plot} ]
do
	day=`echo $d | awk '{printf("%03d",$1)}'`
	if [ -e ${sub}_day${day}.wav_array.csv ]
	then
		printf "$day "
		cat ${sub}_day${day}.wav_array.csv >> $outarray
		cat ${sub}_day${day}_dur.txt >> $meanarray
		rm ${sub}_day${day}.wav_array.csv ${sub}_day${day}_mean.txt
	else
		printf ". "
		echo ",," >> $outarray # Create dummy line for missing data, which gets properly formatted below
		echo "NaN" >> $meanarray
	fi	
	d=`expr $d + 1`
done

# Convert dummy lines to NaNs
cat $outarray | pcut -cs , -cd , -c 1-max | awk -F , '{OFS=","; for (i=1; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' > tmp

# Add the header
cat $array_y_labels tmp > $outarray

echo ""
rm tmp *mp4 *wav

if [ -e ${sub}.voiceRecording.sh ]
then
	chmod 775 ${sub}.voiceRecording.sh
	./${sub}.voiceRecording.sh
else
	${dp_home}/commons/gplot.sh ${outarray} 0 0.04 'Voice Recordings' ${sun1}
	${dp_home}/commons/gplot.sh ${meanarray} 0 100 'Total Duration' ${sun1}
fi

n=`cat ${outarray} | grep -v -c ^NaN`
nan=`cat ${outarray} | grep -c ^NaN`
days=`expr $n + $nan`
pct=`echo "$n $nan" | awk '{printf "%d\%\n",(($1/($1+$2))*100)}'`
png=PNG/`ls -1 | grep .png$ | grep -v mean`
pngmean=PNG/`ls -1 | grep .png$ | grep mean`

if [ `ls -l ${beiweroot} | grep -c ^d` -lt 1 ]
then
	last_date="`ls -l ${beiweroot} | tail -1 | awk '{print $9}'`"
else
	ddir=`ls -l ${beiweroot} | grep ^d - | awk '{print $9}'`
	last_date="`ls -l ${beiweroot}/${ddir} | tail -1 | awk '{print $9}'`"
fi

secs_last=`date -d "${last_date}" +%s`
secs_now=`date +%s`
last_hours=`echo "${secs_now} ${secs_last}" | awk '{print int(($1-$2)/(3600*24))}'`

echo "${n},${pct},${last_hours}" > ${sub}.voiceRecording.info

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.voiceRecording.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Voice Recordings:	'${n}'/'${days}' days collected ('${pct}')</h5></td></tr>' >> ${sub}.voiceRecording.html

echo '<tr><td> <img src="'${pngmean}'" alt="gpsm" align=left width="1200px"></td></tr>' >> ${sub}.voiceRecording.html

echo '<tr><td> <img src="'${png}'" alt="gps" align=left width="1200px"></td></tr>' >> ${sub}.voiceRecording.html

echo '</table>' >> ${sub}.voiceRecording.html

rm *dur.txt

exit 0
