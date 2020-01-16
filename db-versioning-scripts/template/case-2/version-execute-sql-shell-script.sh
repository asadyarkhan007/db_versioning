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
    if [[ $folderName =~ (-to-)([^,]*) ]]; then
        version=${BASH_REMATCH[2]}
    else
        echo "Folder name invalid"
        exit 1
    fi

    # insert into database regarding active version
    if [[ -z $3 ]]; then
        insert_statement="\"INSERT INTO db_version(version) VALUES ('$version');\""
    else
        comment=$3
        insert_statement="\"INSERT INTO db_version(version,comment) VALUES ('$version','$comment');\""  
    fi


    conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $insert_statement"
    # echo $conn_string
    eval $conn_string

    # get last inserted id for foreign key matching 
    select_statement="\"SELECT MAX(id) FROM db_version;\""
    script="mysql -h $host -P $port -u $username -p$password -D $db -P $port --batch -e \"SELECT MAX(id) FROM db_version;\""
    eval $script > tmp
    db_version_id=$(head -2 "tmp" | tail -1)
    rm tmp;


    while IFS= read -r line
    do        
        if [[ $line == *.sql* ]]; then    
            FILE=$(pwd)/$folderName/$line
            echo "Running Script... $FILE"
            conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port < \"$FILE\""
            # echo $conn_string
            eval $conn_string
            if [[ $? == 0 ]]; then
                is_successful=1
            else
                is_successful=0
				echo "One of the Scripts failed. Exiting now..."
				exit 1
            fi

            insert_statement="\"INSERT INTO db_version_script(db_version_id,script_name,is_successful) VALUES ('$db_version_id','$line','$is_successful');\"" 
            conn_string="mysql -h $host -P $port -u $username -p$password -D $db -P $port -e $insert_statement"
            # echo $conn_string
            eval $conn_string

        fi
    done <"$file"
fi
