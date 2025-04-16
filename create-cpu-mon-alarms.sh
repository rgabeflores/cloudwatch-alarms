MFA_PROFILE=mfa

file=$1
action=$2

while IFS= read -r instance; do
	echo "Creating alarm for instance: $instance" 
	aws cloudwatch put-metric-alarm --alarm-name cpu-mon-$instance --alarm-description "Alarm when $instance CPU exceeds 75 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 75 --comparison-operator GreaterThanThreshold  --dimensions "Name=InstanceId,Value=$instance" --evaluation-periods 2 --alarm-actions $action --unit Percent --tags Key=Instance,Value=$instance Key=Description,Value="SOC2 Compliance" --profile $MFA_PROFILE
done < $file
