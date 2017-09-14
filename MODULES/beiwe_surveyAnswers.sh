#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
sub=$1
beiweroot=$2
start_d=$3
end_d=$4
suffix="surveyAnswers"

echo ""
echo "********************************"
echo " Beiwe Survey Answer converter"
echo "********************************"
echo ""
echo "Copying over raw survey answers files for subject $sub "
cp ${beiweroot}/* .

##########################################################
#
#  FOLLOWING SECTION SHOULD BE FIXED FOR ALL DATA TYPES
#
#########################################################

# Remove spaces from files names
rename " " _ *

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

# Compute number of days to plot based on start and end date
days_to_plot=`echo $start_d_sec $end_d_sec | awk '{sec=$2-$1; printf("%03d\n", int(sec/60/60/24)+1)}'`

# Extract header from first survey file
cat `ls *.csv | head -1` | sed 's/Over the past 24 hours how much were you:,,//g' | awk -F ',' '{if(NR>1) printf("%s,", $3)}' >> SA_hdr
echo "" >> SA_hdr

# Set up output files
outarray=${sub}_${suffix}_array.csv
array_y_labels="SA_hdr"


if [ -e $outarray ]
then
	rm -f $outarray
fi

####################################################################################
#
#  OK TO CHANGE THIS SECTION FOR NEW DATA TYPES
#
###################################################################################

# Takes ~30 sec for >1M lines
echo ""
echo "Converting raw survey answers to values relative to consent date "
printf "File"
for file in `ls -1 *.csv | grep -v array`
do
	printf "."
        date=`echo $file | awk -F '_' '{print $1}'`
        date_sec=`date -d $date +%s`
        dos=`echo $start_d_sec $date_sec | awk '{sec=$2-$1; printf("%03d", int(sec/60/60/24)+1)}' CONSENT=$start_d_sec`

	# The following line can be modifed to handle different data types
	cat $file | awk -F ',' '{if(NR>1) print $5,$4}' | tr "[" "," | tr ";" "," | tr "]" " " | sed -e '/ /s///g' | awk -F ',' '{for (i=2;i<=NF;i++) {if($1==$i) printf("%d,", i-2)}}' > ${sub}_${dos}_${suffix}
	echo "" >> ${sub}_${dos}_${suffix}
done

####################################################################
#
#  FOLLOWING SECTION SHOULD REMAIN MOSTLY FIXED FOR ALL DATA TYPES
#
###################################################################

echo ""
echo ""
printf "Compiling table from day "


# Cycle through days to populate [Day X Question] array of values with missing filled in
d=1; 
while [ $d -le ${days_to_plot} ]
do
	day=`echo $d | awk '{printf("%03d\n",$1)}'`
	if [ -e ${sub}_${day}_${suffix} ]
	then
		printf "$day "
		cat ${sub}_${day}_${suffix} >> ${outarray}
		rm ${sub}_${day}_${suffix} 
	else 
                printf ". "
		echo ",," >> ${outarray} # Create dummy line for missing data, which gets properly formatted below
	fi
	d=`expr $d + 1`
done

echo ""
# Convert dummy lines to NaNs
cat $outarray | pcut -cs ',' -cd ',' -c 1-max | awk -F , '{OFS=","; for (i=1; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' > tmp

cat SA_hdr tmp > ${outarray}
sed -i s/^,//g ${outarray}
rm SA_hdr tmp ????-??-??_??_??_??.csv

echo ""
exit 0
