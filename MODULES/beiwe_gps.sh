#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
# Beiewe GPS coordinates processing module.
# Plots hourly mean distance (KM) from home (as determined by modal GPS coordinates at 3am over previous 2 weeks)

#	######## USAGE ######
#	
#	Designed to be called by dp_bw_wrap.sh (which parses input arguments from $study.csv file), but can be called directly as follows: 
#
#	beiwe_gps.sh $sub $rawpath $consent $enddate $study
#	
#	sub = Study ID
#	rawpath = Path to raw GPS data on PHX
#	consent = consent date
#	enddate = last date $sub was enrolled in study, if applicable. Otherwise, today.
#	study = if this needs to be explained, may god (or whatever) help you, because I can't.
#	
#	########################

sub=$1
rawpath=$2
consent=$3
enddate=$4
study=$5

sDOW=`date -d ${consent} +%w`
sun1=`find_sunday $sDOW`

echo ""
echo "****************************************************"
echo " Beiwe GPS converter"
echo "****************************************************"
echo ""
echo "Attempting to unlock encrypted GPS Files for subject $sub "

python ${dp_home}/commons/beiwe_unlocker.py -p ${rawpath} -s ${study}


consent_sec=`date -d $consent +%s`

# Grab home location from most common location across all points
# Can adjust to specific hours, but was failing
lat=`cat ????-??-??_??_??_??.csv | grep -v latitude | awk -F ',' '{printf("%2.6f ", $3)}' | pcut -t | awk '{ for (i=1; i<=NF; ++i) if (max <= ++x[$i]) max = x[$i] } END { for (i in x) if (x[i] == max) print i }' `
long=`cat ????-??-??_??_??_??.csv | grep -v latitude | awk -F ',' '{printf("%2.6f ", $4)}' | pcut -t | awk '{ for (i=1; i<=NF; ++i) if (max <= ++x[$i]) max = x[$i] } END { for (i in x) if (x[i] == max) print i }' `

# Grab day of week for first day of data
dow_D1=`date -d "$consent" "+%w"`

echo ""
echo "Converting raw GPS to distance from home relative to consent date "
printf "File"
for file in *00_00.csv
do
	printf "."
	dos=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*CONSENT); printf("%03d", int(reftime/1000/60/60/24+1))}' CONSENT=$consent_sec`
	hour=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*CONSENT); dos=int(reftime/1000/60/60/24+1); printf("%02d", int((reftime/1000)/60/60-24*(dos-1))); }' CONSENT=$consent_sec` 
	cat $file | grep -v timestamp | awk -F ',' '{reftime=$1-(1000*CONSENT); dos=int(reftime/1000/60/60/24+1); hour=int((reftime/1000)/60/60-24*(dos-1)); dow=(((dos-1)%7)+DOW_D1)%7; d2r=(3.14159265359/180); dlat=((LAT-$3)*d2r); dlong=((LONG-$4)*d2r); a=(sin(dlat/2)*sin(dlat/2))+(cos($1*d2r)*cos($3*d2r)*(sin(dlong/2)*sin(dlong/2))); c=(2*(atan2(sqrt(sqrt(a*a)),sqrt(sqrt((1-a)*(1-a)))))); km=6367*c; if ($6<50) print reftime, dos, dow, hour, km}' CONSENT=$consent_sec DOW_D1=$dow_D1 LAT=$lat LONG=$long >> ${sub}_${dos}_${hour}_disthome
	if [ `cat ${sub}_${dos}_${hour}_disthome | wc -l` -lt 1 ]
	then
		rm ${sub}_${dos}_${hour}_disthome
	fi

done

if [ ! $4 ]
then
	date_sec=`date +%s`
        dos=`echo $consent_sec $date_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`
else
	date_sec=`date -d ${enddate} +%s`
        dos=`echo $consent_sec $date_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`
fi

outsamples=${sub}_gps_disthome_samples.csv
outarray=${sub}_gps_disthome_array.csv
meanarray=${sub}_gps_disthome_array_mean.csv

if [ -e $outarray ]
then
	rm -f $outarray $meanarray $outsamples
fi

cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv > ${outarray}
echo "GPS Distance from Home" > ${meanarray}

echo ""
echo ""
printf "Generating [ $dos x 24 ] array of distance values for day "

# Cycle through days and hours to populate [Day X Hour] array of values with missing filled in
d=1; h=0;
while [ $d -le $dos ]
do
	day=`echo $d | awk '{printf("%03d",$1)}'`
	printf "$day "
	while [ $h -lt 24 ]
	do
		hour=`echo $h | awk '{printf("%02d",$1)}'`
		if [ -e ${sub}_${day}_${hour}_disthome ]
		then
			cat ${sub}_${day}_${hour}_disthome | awk 'BEGIN {R=0; tot=0;} {R++; tot+=$5;} END {printf("%2.5f,", tot/R)}' >> ${outarray}
			cat ${sub}_${day}_${hour}_disthome >> $outsamples
		else 
			printf "NaN," >> ${outarray}
		fi
		h=`expr $h + 1`
	done
	echo "" >> ${outarray}

	d=`expr $d + 1`
	h=0
done

d=1
while [ $d -le $dos ]
do
	day=`echo $d | awk '{printf("%03d",$1)}'`
	# Ideally this next line did not throw errors for missing files
	if stat -t ${sub}_${day}_* >/dev/null 2>/dev/null
	then
		cat ${sub}_${day}_*_disthome | awk 'BEGIN {R=0; tot=0;} {R++; tot+=$5;} END {printf("%2.5f \n", tot/R)}' >> ${meanarray}
	else
		echo "NaN" >> ${meanarray}
	fi

	d=`expr $d + 1`
done


rm *_disthome


if [ -e ${sub}.gps.sh ]
then
	chmod 775 ${sub}.gps.sh
	./${sub}.gps.sh
else
	gplot.sh ${outarray} 0 10 'GPS Mean Distance From Home' ${sun1}
	gplot.sh ${meanarray} 0 10 'Mean' ${sun1}
fi

n=`cat ${outarray}.NaNarray | awk -F , 'BEGIN{nan=0}{for (i=1;i<=NF;i++) if ($i!="NaN") nan++}END{print nan}'`
nan=`cat ${outarray}.NaNarray | awk -F , 'BEGIN{nan=0}{for (i=1;i<=NF;i++) if ($i=="NaN") nan++}END{print nan}'`
hours=`expr $n + $nan`
pct=`echo "$n $nan" | awk '{printf "%d%s\n",(($1/($1+$2))*100), "%"}'`
png=PNG/`ls -1 | grep .png$ | grep -v mean`
pngmean=PNG/`ls -1 | grep .png$ | grep mean`
last_date="`ls -l ${rawpath} | tail -1 | awk '{print $9}'`"
secs_last=`date -d "${last_date}" +%s`
secs_now=`date +%s`
last_hours=`echo "${secs_now} ${secs_last}" | awk '{print int(($1-$2)/(3600*24))}'`

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">' > ${sub}.gps.html

echo '<tr><td><h5 border="1" style="padding-left: 5px; margin:auto; background-color: #D5DBDB; text-align:left;"> Distance from Home (phone):	'${n}'/'${hours}' hours collected ('${pct}')</h5></td></tr>' >> ${sub}.gps.html

echo '<tr><td> <img src="'${pngmean}'" alt="gpsm" align=left width="1200px"></td></tr>' >> ${sub}.gps.html

echo '<tr><td> <img src="'${png}'" alt="gps" align=left width="1200px"></td></tr>' >> ${sub}.gps.html

echo '</table>' >> ${sub}.gps.html

echo "${n},${pct},${last_hours}" > ${sub}.gps.info


echo "GPS distance from Home complete"

#echo "Beginning GPS dintance from McLean"
#
#lat=42.3942245
#long=-71.19137619999998
#
#
#
#
#for file in *00_00.csv
#do
#	printf "."
#	dos=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*CONSENT); printf("%03d", int(reftime/1000/60/60/24+1))}' CONSENT=$consent_sec`
#	hour=`cat $file | grep -v timestamp | head -1 | awk -F ',' '{reftime=$1-(1000*CONSENT); dos=int(reftime/1000/60/60/24+1); printf("%02d", int((reftime/1000)/60/60-24*(dos-1))); }' CONSENT=$consent_sec`
#	cat $file | grep -v timestamp | awk -F ',' '{reftime=$1-(1000*CONSENT); dos=int(reftime/1000/60/60/24+1); hour=int((reftime/1000)/60/60-24*(dos-1)); dow=(((dos-1)%7)+DOW_D1)%7; d2r=(3.14159265359/180); dlat=((LAT-$3)*d2r); dlong=((LONG-$4)*d2r); a=(sin(dlat/2)*sin(dlat/2))+(cos($1*d2r)*cos($3*d2r)*(sin(dlong/2)*sin(dlong/2))); c=(2*(atan2(sqrt(sqrt(a*a)),sqrt(sqrt((1-a)*(1-a)))))); km=6367*c; if ($6<50) print reftime, dos, dow, hour, km}' CONSENT=$consent_sec DOW_D1=$dow_D1 LAT=$lat LONG=$long >> ${sub}_${dos}_${hour}_distmcl
#	if [ `cat ${sub}_${dos}_${hour}_distmcl | wc -l` -lt 1 ]
#	then
#		rm ${sub}_${dos}_${hour}_distmcl
#	fi
#
#done
#rm *00_00.csv
#
#if [ ! $4 ]
#then
#	#edate=`date +%D`
#	date_sec=`date +%s`
#        dos=`echo $consent_sec $date_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`
#else
#	date_sec=`date -d ${enddate} +%s`
#        dos=`echo $consent_sec $date_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`
#fi
#
#outsamples=${sub}_${dos}days_gps_distmcl_samples.csv
#outarray=${sub}_${dos}days_gps_distmcl_array.csv
#meanarray=${sub}_${dos}days_gps_distmcl_array_mean.csv
#
#if [ -e $outarray ]
#then
#	rm -f $outarray $meanarray $outsamples
#fi
#
#cat /ncf/cnl/13/users/jbaker/PSF_SCRIPTS/BEIWE_PLOTTER_SUPPORT/hourheaders.csv > ${outarray}
#echo "GPS Distance from MCL" > ${meanarray}
#
#echo ""
#echo ""
#printf "Generating [ $dos x 24 ] array of distance values for day "
#
## Cycle through days and hours to populate [Day X Hour] array of values with missing filled in
#d=1; h=0;
#while [ $d -le $dos ]
#do
#	day=`echo $d | awk '{printf("%03d",$1)}'`
#	printf "$day "
#	while [ $h -lt 24 ]
#	do
#		hour=`echo $h | awk '{printf("%02d",$1)}'`
#		if [ -e ${sub}_${day}_${hour}_distmcl ]
#		then
#			cat ${sub}_${day}_${hour}_distmcl | awk 'BEGIN {R=0; tot=0;} {R++; tot+=$5;} END {printf("%2.5f,", tot/R)}' >> ${outarray}
#			cat ${sub}_${day}_${hour}_distmcl >> $outsamples
#		else
#			printf "NaN," >> ${outarray}
#		fi
#		h=`expr $h + 1`
#	done
#	echo "" >> ${outarray}
#
#	d=`expr $d + 1`
#	h=0
#done
#
#d=1
#while [ $d -le $dos ]
#do
#	day=`echo $d | awk '{printf("%03d",$1)}'`
#	# Ideally this next line did not throw errors for missing files
#	if stat -t ${sub}_${day}_* >/dev/null 2>/dev/null
#	then
#		cat ${sub}_${day}_*_distmcl | awk 'BEGIN {R=0; tot=0;} {R++; tot+=$5;} END {printf("%2.5f \n", tot/R)}' >> ${meanarray}
#	else
#		echo "NaN" >> ${meanarray}
#	fi
#
#	d=`expr $d + 1`
#done
#
##rm *_distmcl
#rm *_disthome
#echo "GPS distance from MCL complete"
#echo ""
rm *00_00.csv
exit 0
