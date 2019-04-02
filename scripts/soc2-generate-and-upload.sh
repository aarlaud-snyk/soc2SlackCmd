#! /bin/bash
#Echo 'Generating SOC2 report for $1'
sh -x soc2-script.sh $1 $2 

COMPANYNAME="$(echo $1| tr a-z A-Z)"
REPORTNAME='Snyk-SOC2-'$COMPANYNAME'.pdf'

#echo 'Created $REPORTNAME. Uploading to soc2-reports GS bucket'
gsutil cp $REPORTNAME gs://soc2-reports/ 

#echo 'Generating link'
gsutil signurl -d 7d /etc/gsutil-secret-volume/key.json gs://soc2-reports/$REPORTNAME | awk '{print $5}' >> $REPORTNAME.password
