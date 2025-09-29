#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME="$( echo $0 | cut -d "." -f1 )" 
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOG_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run the script with root Privilages"
    exit 1 # failure is other than 0
fi

VALIDATE() { # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e  "$2 ... $R FAILURE $N" tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" tee -a $LOG_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mango repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod  
VALIDATE $? "Enable MangoDB"

systemctl start mongod  
VALIDATE $? "Start MangoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod  
VALIDATE $? "Restarted  MangoDB"

