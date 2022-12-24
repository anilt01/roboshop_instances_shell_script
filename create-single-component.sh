#!/bin/bash

ZONE_ID="Z0842584HS4XKI3IA0U0"
SG_NAME="allow-all"

create_ec2() {
   PRIVATE_IP=$(aws ec2 run-instances \
      --image-id ${AMI_ID} \
      --instance-type t3.micro \
      --security-group-ids ${SGID} \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}]" \
      --instance-market-options "MarketType=Spot,SpotOptions={SpotInstanceType=persistent,InstanceInterruptionBehavior=stop}" \
      | jq '.Instances[].PrivateIpAddress' | sed -e 's/"//g')

sed -e "s/IPADDRESS/${PRIVATE_IP}/" -e "s/COMPONENT/${COMPONENT}/" route53.json >/tmp/record.json
   aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/record.json | jq
}

AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=Centos-8-DevOps-Practice" | jq '.Images[].ImageId' | sed -e 's/"//g')
if [ -z "${AMI_ID}" ]; then
  echo "AMI_ID not found"
  exit 1
fi
SGID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${SG_NAME} | jq  '.SecurityGroups[].GroupId' | sed -e 's/"//g')
if [ -z "${SGID}" ]; then
  echo "Given Security Group does not exit"
  exit 1
fi
   COMPONENT="${COMPONENT}"
if [ -z "${COMPONENT}" ]; then
  echo "component name is missing"
  exit 1
fi
create_ec2
