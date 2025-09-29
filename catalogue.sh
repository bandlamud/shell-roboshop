#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME="$( echo $0 | cut -d "." -f1 )" 
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws89s.fun
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOG_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run the script with root Privilages"
    exit 1 # failure is other than 0
fi

VALIDATE() { # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e  "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}


#### Nodejs
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "DIsabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Craeting system user"
else
    echo -e "User alredy exist .... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Changing app directory"

rm -rf /app/*
VALIDATE $? "Removing exitsing code"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue"
 
npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencys"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "copying catalogue.service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load mongodb"

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

