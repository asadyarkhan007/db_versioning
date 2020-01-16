#!/bin/bash

# Usage: arg1 (Name of the folder) arg2 (Profile dev/uat1/uat2) arg3 [Optional] (Comment to be added)
if [[ -z $1 || -z $2 ]]; then
    echo "Missing Arguments"
    echo "Usage: arg1 (Name of the folder) arg2 (Profile dev/uat1/uat2) arg3 [Optional] (Comment to be added)"
else
    folderName=$1
    profile=$2
    fileName="sequential-execute.txt"

    # dev profile
    if [[ $profile = "dev" || $profile = "DEV" ]]; then
    username="root"
    password="'sualeh'"
    db="servicemarket_business"
    host="localhost"
    port="3306"
    # uat1 profile
    elif [[ $profile = "uat1" || $profile = "UAT1" ]]; then
    username="movesouq"
    password="'4Cwt\`L=)3nDG8A]-'"
    db="servicemarket_business"
    host="uat-1.c3whspkfzyqx.eu-west-1.rds.amazonaws.com"
    port="3306"
    # uat2 profile
    elif [[ $profile = "uat2" || $profile = "UAT2" ]]; then
    username="movesouq"
    password="'4Cwt\`L=)3nDG8A]-'"
    db="servicemarket_business"
    host="uat-1.c3whspkfzyqx.eu-west-1.rds.amazonaws.com"
    port="3306"
    # prod profile
    elif [[ $profile = "prod" || $profile = "PROD" ]]; then
    username="movesouq"
    password="'4Cwt\`L=)3nDG8A]-'"
    db="servicemarket_business"
    host="uat-1.c3whspkfzyqx.eu-west-1.rds.amazonaws.com"
    port="3306"
    fi

    # complete path
    file=$(pwd)/$folderName/$fileName

    # extract version from folder pattern VERSION_FROM-to-VERSION_TO
    if [[ $folderName =~ ([^,]*)(-to-)([^,]*) ]]; then
        version_from=${BASH_REMATCH[1]}
		version=${BASH_REMATCH[3]}
				
    else
        echo "Folder name invalid"
        exit 1
    fi

	# Check previous version
	select_statement="\"SELECT d.version FROM db_version d WHERE d.creation_time = ( SELECT MAX(creation_time) FROM db_version WHERE  is_completed = 1 );\""

	results="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $select_statement"
	eval $results > tmp
	output=$(tail -n +2 "tmp")

	if [  -z "$output" ]; then
		echo "No previous version found. Exiting ...."
		exit 1
	fi
	
	if [[ "$output" != "$version_from" ]]; then
		echo "Version mismatch. Expected Version: \"$output\" Current Version: \"$version_from\""
		exit 1
	fi
	


    # insert into database regarding active version
    if [[ -z $3 ]]; then
        insert_statement="\"INSERT INTO db_version(version, is_completed) VALUES ('$version','1');\""
    else
        comment=$3
        insert_statement="\"INSERT INTO db_version(version,comment, is_completed) VALUES ('$version','$comment','1');\""  
    fi




    conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $insert_statement"
    # echo $conn_string
    eval $conn_string

    # get last inserted id for foreign key matching 
    select_statement="\"SELECT MAX(id) FROM db_version;\""
    script="mysql -h $host -P $port -u $username -p$password -D $db -P $port --batch -e $select_statement"
    eval $script > tmp
    db_version_id=$(head -2 "tmp" | tail -1)
    rm tmp;


    while IFS= read -r line
    do        
        if [[ $line == *.sql* ]]; then    
            FILE=$(pwd)/$folderName/$line
            echo "Running Script... $line"
            conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port < \"$FILE\""
            # echo $conn_string
            eval $conn_string
            if [[ $? == 0 ]]; then
                is_successful=1
            else			
                is_successful=0
				update_statement="\"UPDATE db_version SET is_completed = 0 WHERE id = $db_version_id\""
				conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $update_statement"
				# echo $conn_string

				eval $conn_string
				echo "Script Failed... $line"
				echo -n "Exiting now..."
				exit 1
            fi

            insert_statement="\"INSERT INTO db_version_script(db_version_id,script_name,is_successful) VALUES ('$db_version_id','$line','$is_successful');\"" 
            conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $insert_statement"
            # echo $conn_string
            eval $conn_string

        fi
    done <"$file"
fi
