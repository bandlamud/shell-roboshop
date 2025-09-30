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
MYSQL_HOST=mysql.daws89s.fun

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

dnf install python3 gcc python3-devel -y $LOG_FILE


id roboshop $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Craeting system user"
else
    echo -e "User alredy exist .... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading payment application"

cd /app 
VALIDATE $? "Changing app directory"

rm -rf /app/*
VALIDATE $? "Removing exitsing code" &>>$LOG_FILE

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzip payment"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Deamon relod"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "elabling payment"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "installing mysql"



systemctl restart payment
VALIDATE $? "restart payment"