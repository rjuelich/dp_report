#!/bin/bash

###########################################################
 
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

####################################################################################
#  
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#  1.  FIRST DECIDE ON SUFFIX, Y-AXIS VALUE FILE
#  2.  EITHER COPY FROM RAW OR UNLOCK FOR ENCYRYPTED FILES
#
###################################################################################
datatype="callLog"
echo ""
echo "*********************************"
echo " Beiwe Call Logger" 
echo "*********************************"
echo ""
suffix="beiwe_${datatype}"
rawpath=${beiweroot}
mean_y_label="Duration of Calls"
array_y_labels="${dp_home}/HTML_TEMPLATES/hourheaders.csv"

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
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`

# Compute number of days to plot based on start and end date 
days_to_plot=`echo $start_d_sec $end_d_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`

# Set up output variables
outsamples=${sub}_${datatype}_samples.csv
outarray=${sub}_${datatype}_array.csv
meanarray=${sub}_${datatype}_array_mean.csv

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
echo "Separating out Outgoing, Incoming, and Missed Calls per hour since $start_d  "

# This next line simply transfers all calls into standard format, leaving out the HASH for now 
cat ${rawpath}/*.csv | grep -v timestamp | awk -F ',' '{reftime=$1-(1000*START_D); D=int(reftime/1000/60/60/24+1); H=int(reftime/1000)/60/60-24*(D-1); dow=(((D-1)%7)+DOW_D1)%7; printf("%d,%03d,%02d,%1d,%s,%d\n", reftime, D, H, dow, $4, $5) ;}' START_D=$start_d_sec DOW_D1=$dow_D1 > $outsamples

echo Complete

####################################################################
#  
#  FOLLOWING SECTION SHOULD REMAIN MOSTLY FIXED FOR ALL DATA TYPES
#
###################################################################

printf "Compiling table from day "
# Cycle through days and hours to populate [Day X Hour] array of values ; no missing data for calls, assumes all calls were logged
d=1; h=0;
while [ $d -le $days_to_plot ]
do
	day=`echo $d | awk '{printf("%03d",$1)}'`
	printf "$day "
	while [ $h -lt 24 ]
	do
		hour=`echo $h | awk '{printf("%02d",$1)}'`

		# This next line needs to be modified per datatype
		# Currently grabs just cumulative total within each window
		cat $outsamples | awk -F ',' '{if($2==D && $3==H) print $0}' D=$day H=$hour | awk -F ',' 'BEGIN {R=0; tot=0;} {tot+=$6; R++;} END {printf("%2.5f,", tot)}' H=$hour D=$day >> $outarray

		h=`expr $h + 1`
	done
	echo "" >> ${outarray}
	
	cat $outsamples | awk -F ',' '{if($2==D) print $0}' D=$day | awk -F ',' 'BEGIN {R=0; tot=0;} {tot+=$6; R++;} END {if(R==0) printf("0\n"); else printf("%2.5f\n", tot)}' D=$d >> $meanarray

	d=`expr $d + 1`
	h=0
done

# This pulls off trailing commas
cat $outarray | sed '/,$/s///' > tmp
mv tmp $outarray 

if [ -e ${sub}.callLog.sh ]
then
	chmod 775 ${sub}.callLog.sh
	./${sub}.callLog.sh
else
	${dp_home}/commons/gplot.sh ${outarray} 0 300 'Phone Log' ${sun1}
	${dp_home}/commons/gplot.sh ${meanarray} 0 300 'Mean' ${sun1}
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
echo "${n},${pct},${last_hours}" > ${sub}.callLog.info

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.callLog.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Phone Logs:	'${n}'/'${hours}' hours collected ('${pct}')</h5></td></tr>' >> ${sub}.callLog.html

echo '<tr><td> <img src="'${pngmean}'" alt="gpsm" align=left width="1200px"></td></tr>' >> ${sub}.callLog.html

echo '<tr><td> <img src="'${png}'" alt="gps" align=left width="1200px"></td></tr>' >> ${sub}.callLog.html

echo '</table>' >> ${sub}.callLog.html


echo ""
exit 0
