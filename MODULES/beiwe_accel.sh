#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
sub=$1
beiweroot=$2 
start_d=$3
end_d=$4

####################################################################################
#  
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#  1.  FIRST DECIDE ON SUFFIX, Y-AXIS VALUE FILE
#  2.  EITHER COPY FROM RAW OR UNLOCK FOR ENCYRYPTED FILES
#
###################################################################################
echo ""
echo "*********************************"
echo " Beiwe Accelerometer converter"
echo "*********************************"
echo ""
suffix="beiwe_accel_drms"
rawpath=${beiweroot}
array_y_labels="${dp_home}/HTML_TEMPLATES/hourheaders.csv"
mean_y_label="Accelerometer Delta RMS"

# create symlinks to raw data (removing wretched spaces from filenames)
for i in `ls -1 ${rawpath} | sed 's/ /_/g'`
do
	j=`echo ${i} | awk -F _ '{printf "%s %s_%s_%s\n", $1, $2, $3, $4}'`
	ln -s ${rawpath}/"${j}" ${i}
done

##########################################################
#  
#  FOLLOWING SECTION SHOULD BE FIXED FOR ALL DATA TYPES
#
#########################################################

# Get start day in sec
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
outarray=${sub}_${suffix}_array.csv
meanarray=${sub}_${suffix}_array_mean.csv

if [ -e $outarray ]
then
	rm -f $outarray $meanarray $outsamples
fi

# Start arrays with what will become Y-Axis labels
cat $array_y_labels > $outarray
echo $mean_y_label > $meanarray

####################################################################################
#  
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#
###################################################################################
echo ""
echo "Converting raw accelerometer values to RMS values relative to $start_d  "
printf "File"
for file in *00_00.csv
do
	printf "."

	d=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*START_D); printf("%03d", int(reftime/1000/60/60/24+1))}' START_D=$start_d_sec`
	h=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*START_D); dos=int(reftime/1000/60/60/24+1); printf("%02d", int((reftime/1000)/60/60-24*(dos-1))); }' START_D=$start_d_sec` 
        # This next line computes RMS difference between X,Y,Z columns (cols 5-7) of beiwe accel file
        # By using timestamp, saves new data to correct day and hour
	cat $file | grep -v timestamp | awk -F ',' 'NR==1{oldx=$5; oldy=$6; oldz=$7; next} {reftime=$1-(1000*START_D); dow=(((D-1)%7)+DOW_D1)%7; rms=sqrt(($5-oldx)*($5-oldx) + ($6-oldy)*($6-oldy) + ($7-oldz)*($7-oldz)); print reftime, D, dow, H, rms; oldx=$5; oldy=$6; oldz=$7;}' START_D=$start_d_sec DOW_D1=$dow_D1 D=$d H=$h >> ${sub}_${d}_${h}_${suffix}
done

####################################################################
#  
#  FOLLOWING SECTION SHOULD REMAIN MOSTLY FIXED FOR ALL DATA TYPES
#
###################################################################

printf "Compiling table from day "
# Cycle through days and hours to populate [Day X Hour] array of values with missing filled in
d=1; h=0;
while [ $d -le $days_to_plot ]
do
	day=`echo $d | awk '{printf("%03d",$1)}'`
	printf "$day "
	while [ $h -lt 24 ]
	do
		hour=`echo $h | awk '{printf("%02d",$1)}'`
		if [ -e ${sub}_${day}_${hour}_${suffix} ]
		then
			cat ${sub}_${day}_${hour}_${suffix} | awk 'BEGIN {R=0; tot=0;} {tot+=$5; R++;} END {printf("%2.5f,", tot/R)}' >> $outarray
			cat ${sub}_${day}_${hour}_${suffix} >> $outsamples
		else 
			printf "NaN," >> ${outarray}
		fi
		h=`expr $h + 1`
	done
	echo "" >> ${outarray}
	
	if stat -t ${sub}_${day}_* >/dev/null 2>/dev/null
	then
		cat ${sub}_${day}_*_${suffix} | awk 'BEGIN {R=0; tot=0;} {tot+=$5; R++;} END {printf("%2.5f \n", tot/R)}' >> ${meanarray}
	else
		echo "NaN" >> ${meanarray}
	fi

	d=`expr $d + 1`
	h=0
done
rm *_${suffix} 201*csv


if [ -e ${sub}.accel.sh ]
then
	chmod 775 ${sub}.accel.sh
	./${sub}.accel.sh
else
	${dp_home}/commons/gplot.sh ${outarray} 0 0.6 'Accelerometer' ${sun1}
	${dp_home}/commons/gplot.sh ${meanarray} 0 0.6 'Mean' ${sun1}
fi

n=`cat ${outarray}.NaNarray | awk -F , 'BEGIN{nan=0}{for (i=1;i<=NF;i++) if ($i!="NaN") nan++}END{print nan}'`
nan=`cat ${outarray}.NaNarray | awk -F , 'BEGIN{nan=0}{for (i=1;i<=NF;i++) if ($i=="NaN") nan++}END{print nan}'`
hours=`expr $n + $nan`
pct=`echo "$n $nan" | awk '{printf "%d%s\n",(($1/($1+$2))*100), "\%"}'`
png=PNG/`ls -1 | grep .png$ | grep -v mean`
pngmean=PNG/`ls -1 | grep .png$ | grep mean`

last_date="`ls -l ${beiweroot} | tail -1 | awk '{print $9}'`"
secs_last=`date -d "${last_date}" +%s`
secs_now=`date +%s`
last_hours=`echo "${secs_now} ${secs_last}" | awk '{print int(($1-$2)/(3600*24))}'`

echo "${n},${pct},${last_hours}" > ${sub}.accel.info

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.accel.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Accelerometer (phone):	'${n}'/'${hours}' hours collected ('${pct}')</h5></td></tr>' >> ${sub}.accel.html

echo '<tr><td> <img src="'${pngmean}'" alt="gpsm" align=left width="1200px"></td></tr>' >> ${sub}.accel.html

echo '<tr><td> <img src="'${png}'" alt="gps" align=left width="1200px"></td></tr>' >> ${sub}.accel.html

echo '</table>' >> ${sub}.accel.html

echo ""
exit 0
