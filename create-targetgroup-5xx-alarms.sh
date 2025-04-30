MFA_PROFILE=mfa

file=$1
action=$2
loadbalancer=$3

while IFS= read -r targetgroup; do
	echo "Creating alarm for target group: $targetgroup" 
	aws cloudwatch put-metric-alarm --alarm-name $targetgroup-5XX-count --alarm-description "Alarm when $targetgroup 5XX count is high" --metric-name HTTPCode_Target_5XX_Count --namespace AWS/ApplicationELB --statistic Sum --period 60 --threshold 15 --comparison-operator GreaterThanOrEqualToThreshold --dimensions "Name=LoadBalancer,Value=$loadbalancer" "Name=TargetGroup,Value=$targetgroup" --evaluation-periods 3 --datapoints-to-alarm 2 --alarm-actions $action --treat-missing-data notBreaching --tags Key=TargetGroup,Value=$targetgroup Key=Description,Value="5XX count for target groups" --profile $MFA_PROFILE
done < $file

