MFA_PROFILE=mfa

file=$1
action=$2
loadbalancer=app/mytransit-alb/9a574b1adf56f6be

while IFS= read -r targetgroup; do
	echo "Creating alarm for target group: $targetgroup" 
	aws cloudwatch put-metric-alarm --alarm-name healthy-hosts-$targetgroup --alarm-description "Alarm when $targetgroup healthy hosts goes below 1" --metric-name HealthyHostCount --namespace AWS/ApplicationELB --statistic Average --period 300 --threshold 1 --comparison-operator LessThanThreshold --dimensions "Name=LoadBalancer,Value=$loadbalancer" "Name=TargetGroup,Value=$targetgroup" --evaluation-periods 2 --alarm-actions $action --unit Count --tags Key=TargetGroup,Value=$targetgroup Key=Description,Value="SOC2 Compliance" --profile $MFA_PROFILE
done < $file

