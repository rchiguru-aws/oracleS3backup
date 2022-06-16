## Copyright 2016-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
## Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at
## http://aws.amazon.com/apache2.0/
## or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
## This script is not covered under AWS support.
#!/bin/bash
if [ -z "$1" ]
then
	echo "Please provide a SID as an input parameter"
	exit
fi

export TIMESTAMP=`date +"%Y%m%d%H%M%S"`
SID=`echo "$1" | tr 'a-z' 'A-Z'`
lsid=`echo "${SID}" | tr 'A-Z' 'a-z'`



grep ^ora /etc/passwd | while read user_details
do
#	echo "${user_details}"
	user=`echo $user_details | cut -f1 -d":"`
	if [[ "$user" == "oracle" || "$user" == "ora${lsid}" ]]
	then
		echo "Checking .dbenv files for $user user"
		HOME_DIR=`echo $user_details | cut -f6 -d":"`
#		echo "${HOME_DIR}"
		ls ${HOME_DIR}/.dbenv*.sh | while read dbenv_shell_file
		do
			echo "Processing $dbenv_shell_file"
			if [[ ! `grep "export BR_RCP_CMD=sap-ora-backup-agent" ${dbenv_shell_file}` ]]
			then
				echo "    Entry BR_RCP_CMD does NOT exist in ${dbenv_shell_file} - will update"
				cp ${dbenv_shell_file} ${dbenv_shell_file}.${TIMESTAMP}
 				echo "export BR_RCP_CMD=sap-ora-backup-agent" >> ${dbenv_shell_file}
				echo "    Update completed"
			else
				echo "    Entry already exists"
			fi

			if [[ ! `grep "export BR_RSH_CMD=sap-ora-backup-agent" ${dbenv_shell_file}` ]]
			then
				echo "    Entry BR_RSH_CMD does NOT exist in ${dbenv_shell_file} - will update"
				cp ${dbenv_shell_file} ${dbenv_shell_file}.${TIMESTAMP}
 				echo "export BR_RSH_CMD=sap-ora-backup-agent" >> ${dbenv_shell_file}
				echo "    Update completed"
			else
				echo "    Entry already exists"
			fi
		done
		ls ${HOME_DIR}/.dbenv*.csh | while read dbenv_cshell_file
		do
			echo "Processing $dbenv_cshell_file"
			if [[ ! `grep "setenv BR_RCP_CMD sap-ora-backup-agent" ${dbenv_cshell_file}` ]]
			then
				echo "    Entry BR_RCP_CMD does NOT exist in ${dbenv_cshell_file} - will update"
				cp ${dbenv_cshell_file} ${dbenv_cshell_file}.${TIMESTAMP}
 				echo "setenv BR_RCP_CMD sap-ora-backup-agent" >> ${dbenv_cshell_file}
				echo "    Update completed"
			else
				echo "    Entry already exists"
			fi
			if [[ ! `grep "setenv BR_RSH_CMD sap-ora-backup-agent" ${dbenv_cshell_file}` ]]
			then
				echo "    Entry BR_RSH_CMD does NOT exist in ${dbenv_cshell_file} - will update"
				cp ${dbenv_cshell_file} ${dbenv_cshell_file}.${TIMESTAMP}
 				echo "setenv BR_RSH_CMD sap-ora-backup-agent" >> ${dbenv_cshell_file}
				echo "    Update completed"
			else
				echo "    Entry already exists"
			fi
		done
	fi
done 
