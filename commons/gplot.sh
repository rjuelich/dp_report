#!/bin/bash
##########################################################
 
dp_home="__install_dir__" 

#########################################################
file=$1
min=$2
max=$3
label=$4
sun1=$5
sed -i 's/, $//g' ${file}

head -1 ${file} > ${file}.hdr
n=`wc -l ${file} | awk '{print $1-1}'`
tail -$n $file | /ncf/tools/current/code/bin/pcut -cs , -cd , -t -c 1-max > ${file}.array

# Replace the missing values with NaN before input into matlab

awk -F , '{ OFS=","; for (i=0; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' ${file}.array > ${file}.NaNarray



/ncf/nrg/sw/apps/matlab/7.4/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('${dp_home}/commons'); gplotwc('${file}.NaNarray','${file}.hdr',$min,$max,'${label}',$sun1);quit()" 


stem=`echo $file | sed -e '/\.csv/s///'`
convert -density 300 ${file}.NaNarray.eps -background white -flatten ${stem}_scale${min}to${max}.png

rm ${file}.array ${file}.hdr ${file}.NaNarray ${file}.NaNarray.eps
