#!/bin/bash
## Copyright 2016-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
## Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at
## http://aws.amazon.com/apache2.0/
## or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
## This script is not covered under AWS support.

if [ -z "$1" ]
then
	echo "Please provide the S3 bucket name as an input parameter"
	echo "For example: setup_backup_agent.sh sap-dev-backup-bucket"
	echo "Exiting..."
	exit
fi

if [ -z "$ORACLE_SID}" ]
then
	echo "ORACLE_SID is not set"
	echo "Make sure that you are running this script as the oracle user"
	exit
fi

if [ "${USER}" != "oracle" ]
then
	echo "This script should only be run as the oracle user"
	exit
fi

s3bucket="$1"
SOURCE_DIR=`pwd`
TIMESTAMP=`date +"%Y%m%d%H%M%S"`
if [ ! -d /oracle/${ORACLE_SID}/sapprof ]
then
	echo "Directory /oracle/${ORACLE_SID}/sapprof does not exist!"
	echo "Exiting..."
	exit
fi

cd /oracle/${ORACLE_SID}/sapprof
input_file="initSID.sap"
output_file="init${ORACLE_SID}.new"

if [ ! -f ${input_file} ]
then
	echo "$input_file not found in /oracle/${ORACLE_SID}/sapprof"
	echo "Trying to use init${ORACLE_SID}.sap"
	if [ ! -f init${ORACLE_SID}.sap ]
	then
		echo "init${ORACLE_SID}.sap not found"
		echo "Exiting..."
		exit
	fi
	input_file="init${ORACLE_SID}.sap"
fi

cp ${input_file} ${output_file}

function update_param
{

if [[ `grep ^${param} ${output_file}` ]]
then
	echo "Parameter ${param} exists - updating"
#	echo "sed -i \"s%^${param}.*%${param} = ${param_value}%g\" $output_file"
	sed -i "s%^${param}.*%${param} = ${param_value}%g" $output_file
else
	echo "Parameter ${param} does not exist - inserting"
	echo "${param} = ${param_value}" >> $output_file
fi

}


param="backup_dev_type"
param_value="stage"
update_param

param="stage_root_dir"
param_value="/${ORACLE_SID}_backups"
update_param

param="archive_function"
param_value="save_delete"
update_param

param="archive_stage_dir"
param_value="/${ORACLE_SID}_archivelogs"
update_param

param="stage_copy_cmd"
param_value="rcp"
update_param

param="remote_user"
param_value="s3user"
update_param

param="remote_host"
param_value="s3://${s3bucket}"
update_param

if [ -f init${ORACLE_SID}.sap ]
then
	echo "Backing up existing init${ORACLE_SID}.sap to init${ORACLE_SID}.sap.${TIMESTAMP}"
	cp init${ORACLE_SID}.sap init${ORACLE_SID}.sap.${TIMESTAMP}
	mv init${ORACLE_SID}.new init${ORACLE_SID}.sap
fi

chown oracle:dba init${ORACLE_SID}.sap
chmod 664 init${ORACLE_SID}.sap

BRB_DIR=`which brbackup`
if [ "${BRB_DIR}" = "" ]
then
	echo "Can't find brbackup -it is not in the PATH"
	echo "Exiting..."
	exit
fi

TARGET_DIR=`dirname ${BRB_DIR}`

cd ${TARGET_DIR}
chown oracle:dba sap-ora-backup-agent >/dev/null 2>&1
chmod 775 sap-ora-backup-agent >/dev/null 2>&1

#if [ -L rsh ]
#then
#	mv rsh rsh.${TIMESTAMP}
#fi
#if [ -L rcp ]
#then
#	mv rcp rcp.${TIMESTAMP}
#fi

#echo "Creating soft links"
#ln -s sap-ora-backup-agent rsh
#ln -s sap-ora-backup-agent rcp

echo "Setting S3 performance parameters"
aws configure set default.s3.max_concurrent_requests 20
aws configure set default.s3.multipart_chunksize 16MB


echo "Testing access to S3 bucket ${s3bucket}"
echo -e "    aws s3 ls s3://${s3bucket}\n\n"
aws s3 ls s3://${s3bucket}
if [ $? -ne 0 ]
then
	echo "Unable to access s3://${s3bucket}"
	echo "Please make sure you have assigned a role/policy to this EC2 instance that allows access"
	echo "Once you have done this, you can execute the above command again to test that the access issue has been resolved"
	exit
else
	echo "Command executed successfully"
fi



echo -e "\n\nNow run the following commands as the root user"
echo -e "\n\ncd /tmp/agentinstall"
echo "./root.sh SID from /tmp/agentinstall directory"
echo -e "\n\n"
