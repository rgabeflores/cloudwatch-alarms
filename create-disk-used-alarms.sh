MFA_PROFILE=mfa

file=$1
action=$2

while IFS= read -r instanceid; do
	echo "Creating disk used percent alarm for instance: $instanceid" 
	aws cloudwatch put-metric-alarm --alarm-name disk-used-$instanceid --alarm-description "Alarm when $instanceid disk used percentage is above 85%" --metric-name disk_used_percent --namespace runotp-prod-cwagent --statistic Average --period 60 --threshold 85 --comparison-operator GreaterThanThreshold --dimensions "Name=InstanceId,Value=$instanceid" --evaluation-periods 2 --alarm-actions $action --unit Percent --tags Key=TargetGroup,Value=$instanceid Key=Description,Value="SOC2 Compliance" --profile $MFA_PROFILE
done < $file

