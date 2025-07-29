#!/bin/bash

ENVIRONMENT=production

# Function to print usage
print_usage() {
    echo "Usage: $0 <instance_ids_file> <alarm_action>"
    echo ""
    echo "Parameters:"
    echo "  instance_ids_file  - Path to file containing EC2 instance IDs (one per line)"
    echo "  alarm_action       - SNS topic ARN or action to trigger when alarm fires"
    echo ""
    echo "Example:"
    echo "  $0 instances.txt arn:aws:sns:us-east-1:123456789012:my-topic"
    echo ""
    exit 1
}

# Validate command line parameters
if [[ $# -ne 2 ]]; then
    echo "Error: Invalid number of parameters"
    print_usage
fi

file=$1
action=$2

# Validate that file exists and is readable
if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' does not exist"
    print_usage
fi

if [[ ! -r "$file" ]]; then
    echo "Error: File '$file' is not readable"
    print_usage
fi

# Validate that action is not empty
if [[ -z "$action" ]]; then
    echo "Error: Alarm action cannot be empty"
    print_usage
fi

# Check if file is empty
if [[ ! -s "$file" ]]; then
    echo "Error: File '$file' is empty"
    exit 1
fi

echo "Creating CloudWatch alarms for instances in: $file"
echo "Alarm action: $action"
echo "Environment: $ENVIRONMENT"
echo ""

# Function to sanitize instance name for use in alarm names
sanitize_name() {
    local name="$1"
    # Replace spaces and special characters with hyphens, remove consecutive hyphens
    echo "$name" | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
}

# Function to get instance name from instance ID
get_instance_name() {
    local instanceid="$1"
    local instance_name
    
    # Query AWS to get the Name tag value
    instance_name=$(aws ec2 describe-instances \
        --instance-ids "$instanceid" \
        --query 'Reservations[0].Instances[0].Tags[?Key==`Name`].Value' \
        --output text \
        --profile "$ENVIRONMENT" 2>/dev/null)
    
    # If no name tag found or query failed, use instance ID as fallback
    if [[ -z "$instance_name" || "$instance_name" == "None" ]]; then
        echo "$instanceid"
    else
        # Sanitize the instance name for use in alarm names
        sanitize_name "$instance_name"
    fi
}

while IFS= read -r instanceid; do
    # Skip empty lines
    [[ -z "$instanceid" ]] && continue
    
    # Get the instance name
    instance_name=$(get_instance_name "$instanceid")
    
    echo "Creating disk used percent alarm for instance: $instanceid (Name: $instance_name)"
    
    aws cloudwatch put-metric-alarm \
        --alarm-name "disk-used-$instance_name" \
        --alarm-description "Alarm when $instanceid ($instance_name) disk used percentage is above 85%" \
        --metric-name disk_used_percent \
        --namespace runotp-prod-cwagent \
        --statistic Average \
        --period 60 \
        --threshold 85 \
        --comparison-operator GreaterThanThreshold \
        --dimensions "Name=InstanceId,Value=$instanceid" \
        --evaluation-periods 2 \
        --alarm-actions "$action" \
        --unit Percent \
        --tags "Key=Instance,Value=$instanceid" "Key=InstanceName,Value=$instance_name" "Key=Description,Value=SOC2 Compliance" \
        --profile "$ENVIRONMENT"
        
done < "$file"