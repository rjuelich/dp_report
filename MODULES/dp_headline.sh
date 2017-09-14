#!/bin/sh
#
#    dp_headline.sh:   Create small table with full-width headline

headline=$1

echo '<table border="1" cellpadding="2"  cellspacing="0" width="1200px" style="border-collapse: separate; margin:auto;">'
echo '<tr><td><h4 border="1" style="margin:auto; background-color:#999999; text-align:center; border-collapse: collapse;">'$headline'</h4></td></tr>'
echo '</table>' 
