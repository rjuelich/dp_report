#!/bin/bash

study=$1
sub=$2
out_home=$3

phx="/ncf/cnl03/PHOENIX/GENERAL"
if [ ! $4 ]
then
	end_d=`date +%F`
else
	end_d=$4
fi
scripts_dir="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS"
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/DP_HOME"
dp_modules="${{dp_home}/MODULES"
start_d=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $5}'`

cd ${out_home}/${sub}/dp_grids

rm ${sub}*png ${sub}*html

cp ${out_home}/${sub}/dp_grids/HTML/${sub}_DPreport.html ${scripts_dir}/BEIWE_HTML/diphyre_logo.png ${scripts_dir}/BEIWE_HTML/w3.css ./

for png in phone actigraphy mri
do
	find ${out_home}/${sub}/${png} -name "*.png" -exec cp '{}' ./ \;
done

dp_png_buffer.sh

wkhtmltopdf --load-media-error-handling skip --allow `pwd` -T 1mm -R 1mm -L 1mm -B 1mm --page-width 216mm --page-height 300mm ${sub}_DPreport.html ${sub}_DPreport.pdf


