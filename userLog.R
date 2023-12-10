###############################################################
#### Get User Logs 
###############################################################
rm(list=ls())
setwd("C:/Users/Sid/Documents/R/Projects/PKG_Data_Project")
library(data.table)

library(RMariaDB)
db_user <- 'pkgdata'
db_password <- 'sox58kir'
db_name <- 'pkgdata+registrationData'
db_table <- 'UserLog'
db_host <- 'sql.mit.edu' 

# Connecting to MySQL DB
stuffDB <- dbConnect(MariaDB(), user = db_user, password = db_password, dbname = db_name, host = db_host)

# Read Database
userLog = dbReadTable(stuffDB,name = db_table)

#Close connection
dbDisconnect(stuffDB)
