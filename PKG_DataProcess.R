rm(list=ls())
setwd("C:/Users/Sid/Documents/R/Projects/PKGDataProject/PKGData")
library(data.table)

############################################################################
####  Download Updated Google Form Data and save in ./csvData 
############################################################################
# Registration - https://docs.google.com/spreadsheets/d/1IPzkIt_4ijQ3Pl0HVmDNNb89BNcwcM1FtV3diBMLt2M/edit#gid=1152325235
# Completion - https://docs.google.com/spreadsheets/d/1EzokPuda2DBdiU7odb0KbTmAt8eZSl5J--6LDiOhxKg/edit#gid=592683361


############################################################################
####  Also include legacy data from old forms (no need to update these)
############################################################################

# PKG Student Quick Registration_Legacy_Data.csv
# FY21_Legacy_Data_Collection.csv

###############################################################
#### PKG Registration Data
###############################################################

### Get old data, up to 5/8/2022
legacyReg = readRDS('./csvData/PKG_Registration_Data_Legacy_5_8_2022.RDS')

### Get new data, after 5/8/2022
table = data.table(read.csv('./csvData/PKG Student Registration (Responses) - Form Responses 1.csv'))

### Get Column Names to make sure input Table is formatted correctly
regnames = readRDS(file='./supportData/RegTable_Names.RDS')
if(all.equal(regnames,names(table))!=TRUE){
  stop('Error : Reg Table incorrectly formatted')
}

setnames(table,names(table),c('TimeStamp','PKGProgram','FirstName','LastName','Email','StudentType','Race',
                              'Gender','MIT_ID','GradYear','FSILG','Department','Pipeline','Q1_LearnSI','Q1_LearnVS',
                              'Q1_LearnSocPol','Q1_LearnLead','Q1_ParticPol','Q2_ImpContext','Q2_ImpExp','Q2_ImpSkill',
                              'Q2_ImpRes','Q2_ImpNet','Q3_EquipVol','Q3_EquipCom','Q3_EquipCareer','Comments','ProgramSem','ProgramYear','DEIStatement'))


### Standardize Data Table for Gender Inputs
table[Gender=='',Gender:='No response']
table[,GenderNotes:=Gender]

### Standardize Data Table for Race Inputs
table[Race=='',Race:='No response']
table[,RaceNotes:=Race]

### Standardize Data Table for PKG Program Inputs
table[,PKGProgramNotes:=PKGProgram]
table[ProgramSem == '',ProgramSem:='No Data']

table[is.na(table)] <- ''

table$UID = 1329:(1329+length(table$TimeStamp)-1)

### Merge Old and New Data
tableFullFinal = rbind(legacyReg,table)


### QA - QC with duplicate program names
tableFullFinal[PKGProgram=='SP.256',PKGProgram:='SP.256 Informed Philanthropy in Theory and Action']
tableFullFinal[PKGProgram=='SP.250',PKGProgram:='SP.250 Transforming Good Intentions into Good Outcomes']
tableFullFinal[PKGProgram=='Fellowships',PKGProgram:='PKG Fellowships Program']
tableFullFinal[PKGProgram=='IDEAS',PKGProgram:='IDEAS Social Innovation Challenge']
tableFullFinal[PKGProgram=='Internships',PKGProgram:='Social Impact Internships']
tableFullFinal[PKGProgram=='Work Study',PKGProgram:='Community Based Federal Work Study']
tableFullFinal[PKGProgram=='CIFI',PKGProgram:='Community-Informed Field Immersion (CIFI)']
tableFullFinal[PKGProgram=='ACE',PKGProgram:='Active Community Engagement (ACE)']
tableFullFinal[PKGProgram=='Connect',PKGProgram:='Summer Immersion: PKG Connect']
tableFullFinal[PKGProgram=='IDEAS Events',PKGProgram:='IDEAS Workshops and Events']
tableFullFinal = tableFullFinal[PKGProgram!='Unknown']

#### Save Data for backup
timeString = gsub(" ","_",Sys.time())
timeString = gsub(":","_",timeString)
saveRDS(tableFullFinal,file=paste('./processedData/PKG_Registration_Data_',timeString,'.RDS',sep=''))
saveRDS(tableFullFinal,file=paste('./processedData/PKG_Registration_Data_MostRecent.RDS',sep=''))


#### Get DT for Registrar - Feel free to filter by year or sem if required
tableRegistrar = tableFullFinal[,.(Email,MIT_ID,PKGProgram,ProgramYear)]
tableRegistrar = tableRegistrar[Email %like% "mit.edu",]
tableRegistrar = tableRegistrar[order(PKGProgram,ProgramYear),]
write.csv(tableRegistrar,file=paste('./processedData/RegistrarData_Registration.csv'))

###############################################################
#### Push Registration Data to PKG Web Portal
###############################################################

library(RMariaDB)
db_user <- 'pkgdata'
db_password <- 'sox58kir'
db_name <- 'pkgdata+registrationData'
db_table <- 'Registration'
db_host <- 'sql.mit.edu' 


# Connecting to MySQL DB
stuffDB <- dbConnect(MariaDB(), user = db_user, password = db_password, dbname = db_name, host = db_host)

# List tables in DB
dbListTables(stuffDB)

# Write to Database in Batches of 500
dbWriteTable(stuffDB, value = tableFullFinal[1:500], row.names = FALSE, name = "Registration",field.types = c(`TimeStamp`="varchar(200)",
                                                                                                              `PKGProgram`="varchar(200)",
                                                                                                              `FirstName`="varchar(200)",
                                                                                                              `LastName`="varchar(200)",
                                                                                                              `Email`="varchar(200)",
                                                                                                              `StudentType`="varchar(200)",
                                                                                                              `Race`="varchar(200)",
                                                                                                              `Gender`="varchar(200)",
                                                                                                              `MIT_ID`="varchar(200)",
                                                                                                              `GradYear`="varchar(200)",
                                                                                                              `FSILG`="varchar(200)",
                                                                                                              `Department`="varchar(200)",
                                                                                                              `Pipeline`="varchar(200)",
                                                                                                              `Q1_LearnSI`="int",
                                                                                                              `Q1_LearnVS`="int",
                                                                                                              `Q1_LearnSocPol`="int",
                                                                                                              `Q1_LearnLead`="int",
                                                                                                              `Q1_ParticPol`="int",
                                                                                                              `Q2_ImpContext`="int",
                                                                                                              `Q2_ImpExp`="int",
                                                                                                              `Q2_ImpSkill`="int",
                                                                                                              `Q2_ImpRes`="int",
                                                                                                              `Q2_ImpNet`="int",
                                                                                                              `Q3_EquipVol`="int",
                                                                                                              `Q3_EquipCom`="int",
                                                                                                              `Q3_EquipCareer`="int",
                                                                                                              `Comments`="text",
                                                                                                              `ProgramSem`="varchar(200)",
                                                                                                              `ProgramYear`="varchar(200)",
                                                                                                              `GenderNotes`="varchar(200)",
                                                                                                              `RaceNotes`="varchar(200)",
                                                                                                              `PKGProgramNotes`="varchar(200)",
                                                                                                              `UID`="int"),
             overwrite = TRUE)
dbWriteTable(stuffDB, value = tableFullFinal[501:1000], row.names = FALSE, name = "Registration", overwrite = FALSE, append = TRUE)
dbWriteTable(stuffDB, value = tableFullFinal[1001:length(tableFullFinal$TimeStamp)], row.names = FALSE, name = "Registration", overwrite = FALSE, append = TRUE)

################### Send MetaData 
metaTable = data.table(UpdateTime=as.character(Sys.time()))
dbWriteTable(stuffDB, value = metaTable, row.names = FALSE, name = "MetaData", overwrite = TRUE)

#Close connection
dbDisconnect(stuffDB)



###############################################################
#### PKG Completion Data
###############################################################
rm(list=ls())
setwd("C:/Users/Sid/Documents/R/Projects/PKGDataProject/PKGData")
library(data.table)

############################## Merge Demographic Data from Final Registration Table
table = readRDS(file='./processedData/PKG_Registration_Data_MostRecent.RDS')
getRace = function(MITID){
  output = unique(table[MIT_ID==MITID,]$Race)
  if(length(output)==0){
    return('No response')
  } else if(length(output)>1){
    output = output[output!='No response']
    if(length(output)==1){
      return(output)
    }else {
      return('Other')
    }
  } else {
    return(output)
  }
}

getGender = function(MITID){
  output = unique(table[MIT_ID==MITID,]$Gender)
  if(length(output)==0){
    return('No response')
  } else if(length(output)>1){
    output = output[output!='No response']
    if(length(output)==1){
      return(output)
    }else {
      return('Other')
    }
  } else {
    return(output)
  }
}


#########################################

tableComplete = data.table(read.csv('./csvData/PKG Program Completion (Responses) - Form Responses 1.csv'))

#### Subset table for General Values that are common across all programs
completionNames = readRDS(file='./supportData/CompletionTable_Names.RDS')
newCols = c('TimeStamp','MIT_ID','Email','PKGProgram','LearningFeedback',
            'Q1Contribute_SI','Q1Contribute_USC','Q1Contribute_Skill','Q1Contribute_Network','Q1Contribute_Res',
            'Q2Interest_Context','Q2Interest_USC','Q2Interest_Skill','Q2Interest_Res','Q2Interest_Network',
            'Q3Equip_Vol','Q3Equip_Community','Q3Equip_Career','PKG_Ambassador','OptionalFeedback','ProgramSem','ProgramYear',
            'FirstName','LastName','StudentType','Department')
setnames(tableComplete,completionNames,newCols)
                        
tableComplete = tableComplete[,newCols,with=F]  
tableComplete[,Race:=mapply(getRace,MIT_ID)]
tableComplete[,Gender:=mapply(getGender,MIT_ID)]

tableLegacy = readRDS(file='./csvData/PKG_Completion_Data_Legacy_5_8_2022.RDS')

### Merge Old and New Data
tableComplete = rbind(tableLegacy,tableComplete)
tableComplete[,Race:=unlist(Race)]
tableComplete[,Gender:=unlist(Gender)]

### QA - QC
tableComplete[PKGProgram=='SP.251',PKGProgram:='SP.251 How to Change the World: Experiences from Social Entrepreneurs (In partnership with SOLVE)']
tableComplete[PKGProgram=='SP.250',PKGProgram:='SP.250 Transforming Good Intentions into Good Outcomes']
tableComplete[PKGProgram=='Fellowships',PKGProgram:='PKG Fellowships Program']
tableComplete[PKGProgram=='IDEAS',PKGProgram:='IDEAS Social Innovation Challenge']
tableComplete[PKGProgram=='Internships',PKGProgram:='Social Impact Internships']
tableComplete[PKGProgram=='Work Study',PKGProgram:='Community Based Federal Work Study']
tableComplete[PKGProgram=='CIFI',PKGProgram:='Community-Informed Field Immersion (CIFI)']
tableComplete[PKGProgram=='ACE',PKGProgram:='Active Community Engagement (ACE)']
tableComplete[PKGProgram=='Connect',PKGProgram:='Summer Immersion: PKG Connect']
tableComplete[PKGProgram=='IDEAS Events',PKGProgram:='IDEAS Workshops and Events']
tableComplete = tableComplete[PKGProgram!='Unknown']


#### Save Data for backup
timeString = gsub(" ","_",Sys.time())
timeString = gsub(":","_",timeString)
saveRDS(tableComplete,file=paste('./processedData/PKG_Completion_Data_',timeString,'.RDS',sep=''))
saveRDS(tableComplete,file=paste('./processedData/PKG_Completion_Data_MostRecent.RDS',sep=''))

#### Get DT for Registrar
tableRegistrarComp = tableComplete[,.(Email,MIT_ID,PKGProgram,ProgramYear)]
tableRegistrarComp = tableRegistrarComp[Email %like% "mit.edu",]
tableRegistrarComp = tableRegistrarComp[order(PKGProgram,ProgramYear),]
write.csv(tableRegistrarComp,file=paste('./processedData/RegistrarData_Completion.csv'))

####### Push Data to PKG Web Portal
library(RMariaDB)
db_user <- 'pkgdata'
db_password <- 'sox58kir'
db_name <- 'pkgdata+registrationData'
db_table <- 'CompletionData'
db_host <- 'sql.mit.edu' 


# Connecting to MySQL DB
stuffDB <- dbConnect(MariaDB(), user = db_user, password = db_password, dbname = db_name, host = db_host)

# List tables in DB
dbListTables(stuffDB)

# Write to Database
dbWriteTable(stuffDB, value = tableComplete, row.names = FALSE, name = db_table, field.types = c(`TimeStamp`="varchar(200)",
                                                                                                 `MIT_ID`="varchar(200)",
                                                                                                 `Email`="varchar(200)",
                                                                                                 `PKGProgram`="varchar(200)",
                                                                                                 `LearningFeedback`="text",
                                                                                                 `Q1Contribute_SI`="varchar(200)",
                                                                                                 `Q1Contribute_USC`="varchar(200)",
                                                                                                 `Q1Contribute_Skill`="varchar(200)",
                                                                                                 `Q1Contribute_Network`="varchar(200)",
                                                                                                 `Q1Contribute_Res`="varchar(200)",
                                                                                                 `Q2Interest_Context`="varchar(200)",
                                                                                                 `Q2Interest_USC`="varchar(200)",
                                                                                                 `Q2Interest_Skill`="varchar(200)",
                                                                                                 `Q2Interest_Res`="varchar(200)",
                                                                                                 `Q2Interest_Network`="varchar(200)",
                                                                                                 `Q3Equip_Vol`="varchar(200)",
                                                                                                 `Q3Equip_Community`="varchar(200)",
                                                                                                 `Q3Equip_Career`="varchar(200)",
                                                                                                 `PKG_Ambassador`="varchar(200)",
                                                                                                 `OptionalFeedback`="text",
                                                                                                 `ProgramSem`="varchar(200)",
                                                                                                 `ProgramYear`="varchar(200)",
                                                                                                 `FirstName`="varchar(200)",
                                                                                                 `LastName`="varchar(200)",
                                                                                                 `Race`="varchar(200)",
                                                                                                 `Gender`="varchar(200)",
                                                                                                 `StudentType`="varchar(200)",
                                                                                                 `Department`="varchar(200)"),
                                                                                  overwrite = TRUE)

#Close connection
dbDisconnect(stuffDB)


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


###############################################################
#### Old Code for Handling Legacy Data - No Need to Run, Just for Reference
###############################################################



# ########################################### 
# ### Standardize Data Table Inputs
# ###########################################
# 
# ### Standardize Data Table for Gender Inputs
# table[,GenderNotes:=Gender]
# table[Gender=='',Gender:='No response']
# table[!Gender %in% c('She/Her/Hers','He/His/Him','They/Them','No response'),Gender:="Other"]
# 
# ### Standardize Data Table for Race Inputs
# table[,RaceNotes:=Race]
# table[Race %in% c('African American','Black','Black/African American ','Black/African-American',
#                   'Black/African-American/Sudanese','African American / Black','African American','Black/African American','Black Mixed',
#                   'Black/African American','Black/African-American/Sudanese'),Race:='Black / African American']
# table[Race %in% c('Asian American','Asian','Asian-American','South Asian'),Race:='Asian / South Asian American']
# table[Race %in% c('Hispanic','Latinx','Hispanic/Latino','hispanic/latino','Hispanic','Latino','Hispanic '),Race:='Hispanic / Latinx American']
# table[Race %in% c('Caucasian','white','White','Caucasian '),Race:='White / Caucasian American']
# table[Race=='',Race:='No response']
# table[!Race %in% c('White / Caucasian American','Black / African American','Asian / South Asian American','Hispanic / Latinx American','No response'),Race:='Other']
# 
# ### Standardize Data Table for PKG Program Inputs
# unique(table$PKGProgram)
# table[,PKGProgramNotes:=PKGProgram]
# table[PKGProgram=='Community-Informed Field Immersion (CIFI) - Fall ELO',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='Community-Informed Field Immersion (CIFI) - Summer ELO',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='CIFI - Spring ELO',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='CIFI -Spring ELO',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='Community-Informed Field Immersion (CIFI) - Spring ELO',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='PKG CIFI Program with COPE',PKGProgram:='Community-Informed Field Immersion']
# table[PKGProgram=='Social Impact Internships and Employment',PKGProgram:='Social Impact Internships']
# 
# table[PKGProgram=='ACE Intensive - Fall ELO',PKGProgram:='ACE Intensive - ELO']
# table[PKGProgram=='IDEAS Social Innovation Challenge',PKGProgram:='IDEAS']
# table[PKGProgram=='IDEAS - SBC -IAP/Spring ELO',PKGProgram:='IDEAS ELO']
# table[PKGProgram=='IDEAS - SBC - IAP/Spring ELO',PKGProgram:='IDEAS ELO']
# table[PKGProgram=='Fellowships Program',PKGProgram:='Fellowships']
# table[PKGProgram=='AAPIP',PKGProgram:='Social Impact Internships']
# 
# ### Standardize Data Table for Department Inputs
# table[Department == '', Department:='Other']
# 
# ### Standardize Data Table Term Inputs for Select Programs
# table[PKGProgram=='ACE Intensive - ELO' & ProgramSem=='',ProgramSem:='Fall']
# table[PKGProgram=='IDEAS ELO' & ProgramSem=='',ProgramSem:='IAP']
# table[PKGProgram=='IDEAS' & ProgramSem=='',ProgramSem:='Fall']
# table[PKGProgram=='Fellowships' & ProgramSem=='',ProgramSem:='Spring']
# table[PKGProgram=='Community-Informed Field Immersion - ELO' & ProgramSem=='',ProgramSem:='Fall']
# table[PKGProgram=='Social Impact Internships and Employment' & ProgramSem=='',ProgramSem:='Fall']
# table[PKGProgram=='PKG IAP: Health' & ProgramSem=='',ProgramSem:='IAP']
# table[PKGProgram=='Civic Engagement and Voting' & ProgramSem=='',ProgramSem:='Fall']
# table[ProgramSem == '',ProgramSem:='No Data']
# 
# table[is.na(table)] <- ''
# 
# 
# ########################################### 
# #### Support Functions
# ########################################### 
# 
# ############################## Merge Demographic Data
# 
# getRace = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$Race)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[output!='No response']
#     if(length(output)==1){
#       return(output)
#     }else {
#       return('Other')
#     }
#   } else {
#     return(output)
#   }
# }
# 
# getGender = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$Gender)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[output!='No response']
#     if(length(output)==1){
#       return(output)
#     }else {
#       return('Other')
#     }
#   } else {
#     return(output)
#   }
# }
# 
# getStudentType = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$StudentType)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getDepartment = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$Department)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getFN = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$FirstName)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getLN = function(MITID){
#   output = unique(table[MIT_ID==MITID,]$LastName)
#   if(length(output)==0){
#     return('')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# 
# getFNEmail = function(EmailIn){
#   output = unique(table[Email==EmailIn,]$FirstName)
#   if(length(output)==0){
#     return('No response')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getLNEmail = function(EmailIn){
#   output = unique(table[Email==EmailIn,]$LastName)
#   if(length(output)==0){
#     return('')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getMITID = function(EmailIn){
#   output = unique(table[Email==EmailIn,]$MIT_ID)
#   if(length(output)==0){
#     return('')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getGradYear = function(EmailIn){
#   output = unique(table[Email==EmailIn,]$GradYear)
#   if(length(output)==0){
#     return('')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getFSILG = function(EmailIn){
#   output = unique(table[Email==EmailIn,]$FSILG)
#   if(length(output)==0){
#     return('')
#   } else if(length(output)>1){
#     output = output[length(output)] # Choose the most recent entry
#   } else {
#     return(output)
#   }
# }
# 
# getAcademicYear = function(TimeStamp){
#   year = as.numeric(format(as.Date(TimeStamp, format="%m/%d/%Y %H:%M"),"%Y"))
#   month = as.numeric(format(as.Date(TimeStamp, format="%m/%d/%Y %H:%M"),"%m"))
#   yearList = c('2020'='2020-2021','2021'='2021-2022','2022'='2022-2023')
#   if(month<6){
#     year=year-1
#   }
#   return(yearList[as.character(year)])
# }
# 
# getAcademicSem = function(TimeStamp){
#   month = as.numeric(format(as.Date(TimeStamp, format="%m/%d/%Y %H:%M:%S"),"%m"))
#   if(month %in% c(2,3,4,5)){
#     sem='Spring'
#   }else if(month %in% c(6,7,8)){
#     sem='Summer'
#   }else if(month %in% c(9,10,11,12)){
#     sem='Fall'
#   }else if(month==1){
#     sem='IAP'
#   }
#   return(sem)
# }
# 
# 
# ################################################ 
# #### PKG Quick Registration Data - Legacy Data
# ################################################ 
# 
# tableQR = data.table(read.csv('./csvData/PKG Student Quick Registration_Legacy_Data.csv'))
# 
# setnames(tableQR,names(tableQR),c('TimeStamp','PKGProgram','StudentType','Race','Gender','Department','Pipeline',
#                                   'Email','Comments','DEIStatement','FirstName','X','LastName','MIT_ID'))
# 
# tableQR[,ProgramYear:=mapply(getAcademicYear,TimeStamp)]
# tableQR[,ProgramSem:=mapply(getAcademicSem,TimeStamp)]
# tableQR[FirstName=='',FirstName:=mapply(getFNEmail,EmailIn=Email)]
# tableQR[LastName=='',LastName:=mapply(getLNEmail,EmailIn=Email)]
# tableQR[MIT_ID=='',MIT_ID:=mapply(getMITID,EmailIn=Email)]
# tableQR[,GradYear:=mapply(getGradYear,EmailIn=Email)]
# tableQR[,FSILG:=mapply(getFSILG,EmailIn=Email)]
# tableQR[,Comments:=as.character(Comments)]
# tableQR[is.na(Comments),Comments:='']
# tableQR[is.na(Comments),Comments:='']
# tableQR[Gender=='',Gender:='No response']
# tableQR[Race=='',Race:='No response']
# tableQR[!Race %in% c('White / Caucasian American','Black / African American','Asian / South Asian American','Hispanic / Latinx American','No response'),Race:='Other']
# 
# tableAllRegistration = rbind(table,tableQR, fill=TRUE)
# tableAllRegistration[ProgramYear=='',ProgramYear:=mapply(getAcademicYear,TimeStamp)]
# tableAllRegistration[, ProgramYear:=as.character(ProgramYear)]
# 
# 
# ###############################################################
# #### PKG Manual Registration Data (from Maura)
# ###############################################################
# 
# tableManualReg = data.table(read.csv('./csvData/FY21_Legacy_Data_Collection.csv'))
# setnames(tableManualReg,names(tableManualReg),c('PKGProgramNotes','PKGProgram','MIT_ID','FirstName','LastName',
#                                                 'Email','GradYear','Department','Department2','Race','Gender','Pipeline','Comments'))
# tableManualReg[Department=='',Department:=Department2]
# tableManualReg[GradYear==2024 & Department=='Undecided',StudentType:='Undergraduate']
# tableManualReg[GradYear=='G',StudentType:='Graduate']
# tableManualReg[GradYear=='undergraduate',StudentType:='Undergraduate']
# tableManualReg[GradYear=='UG',StudentType:='Undergraduate']
# tableManualReg[GradYear==2021,StudentType:='Undergraduate']
# tableManualReg[GradYear==2022,StudentType:='Undergraduate']
# tableManualReg[GradYear==2023,StudentType:='Undergraduate']
# tableManualReg[GradYear==2020,StudentType:='Undergraduate']
# tableManualReg[GradYear=='Graduate (PhD)',StudentType:='Graduate']
# tableManualReg[GradYear=='Graduate (Masters)',StudentType:='Graduate']
# tableManualReg[GradYear=='graduate (PhD)',StudentType:='Graduate']
# tableManualReg[GradYear=='graduate (masters)',StudentType:='Graduate']
# tableManualReg[GradYear=='G 2021',StudentType:='Graduate']
# tableManualReg[GradYear=='G',StudentType:='Graduate']
# tableManualReg[GradYear=='Incoming student (MBA)',StudentType:='Graduate']
# tableManualReg[GradYear=='MIT Alumni',StudentType:='Other']
# tableManualReg[GradYear=='MIT Staff',StudentType:='Other']
# tableManualReg[GradYear=='Lecturer',StudentType:='Other']
# tableManualReg[GradYear=='Non-MIT Student',StudentType:='Other']
# tableManualReg[GradYear=='Recent grad',StudentType:='Other']
# tableManualReg[GradYear=='Cofounder w/ MIT',StudentType:='Other']
# tableManualReg[GradYear=='Alum',StudentType:='Other']
# tableManualReg[GradYear=='Other',StudentType:='No response']
# tableManualReg[GradYear=='',StudentType:='No response']
# tableManualReg[Pipeline=='',Pipeline:='No response']
# 
# tableManualReg[Department=='Course 6 Electrical Engineering and Computer Science',Department:='Course 6 - Electrical Engineering and Computer Science']
# tableManualReg[Department=='Course 10 Chemical Engineering',Department:='Course 10 - Chemical Engineering']
# tableManualReg[Department=='Course 20 Biological Engineering',Department:='Course 20 - Biological Engineering']
# tableManualReg[Department=='Course 7 Biology',Department:='Course 7 - Biology']
# tableManualReg[Department=='',Department:='No response']
# tableManualReg[Department=='Course 2 Mechanical Engineering',Department:='Course 2 - Mechanical Engineering']
# tableManualReg[Department=='Course 11 Urban Studies and Planning',Department:='Course 11 - Urban Studies and Planning']
# tableManualReg[Department=='Course 16 Aeronautics and Astronautics',Department:='Course 16 - Aeronautics and Astronautics']
# tableManualReg[Department=='Undecided',Department:='Undeclared']
# tableManualReg[Department=='MAS Media Arts and Sciences',Department:='MAS - Media Arts and Science']
# tableManualReg[Department=='Course 21W Comparative Media Studies / Writing',Department:='CMS/21W - Comparative Media Studies / Writing']
# tableManualReg[Department=='Course 18 Mathematics',Department:='Course 18 - Mathematics']
# tableManualReg[Department=='Course 4 Architecture',Department:='Course 4 - Architecture']
# tableManualReg[Department=='HASTS',Department:='21H - History']
# tableManualReg[Department=='Course 15 Management',Department:='Course 15 - Management']
# tableManualReg[Department=='IDM Integrated Design & Management',Department:='IDM - Integrated Design & Management']
# tableManualReg[Department=='Course 9 Brain and Cognitive Sciences',Department:='Course 9 - Brain and Cognitive Sciences']
# tableManualReg[Department=='Course 1 Civil and Environmental Engineering',Department:='Course 1 - Civil and Environmental Engineering']
# tableManualReg[Department=='Course 8 Physics',Department:='Course 8 - Physics']
# tableManualReg[Department=='CMS/W Comparative Media Studies / Writing',Department:='CMS/21W - Comparative Media Studies / Writing']
# tableManualReg[Department=='Course 22 Nuclear Science and Engineering',Department:='Course 22 - Nuclear Science and Engineering']
# tableManualReg[Department=='Course 14 Economics',Department:='Course 14 - Economics']
# tableManualReg[Department=='Course 3 Materials Science and Engineering',Department:='Course 3 - Materials Science and Engineering']
# tableManualReg[Department=='SDM System Design & Management',Department:='SDM - System Design and Management']
# tableManualReg[Department=='TPP Technology and Policy Program',Department:='TPP - Technology and Policy Program']
# tableManualReg[Department=='Middle East Entrepreneurs of Tomorrow',Department:='Other']
# tableManualReg[Department=='SCM Supply Chain Management',Department:='SCM - Supply Chain Management']
# tableManualReg[Department=='Middle East Entrepreneurs of Tomorrow',Department:='Other']
# tableManualReg[Department=='Entrepreneurship',Department:='Other']
# tableManualReg[Department=='Harvard',Department:='Other']
# tableManualReg[Department=='Fellow at Harvard Dept. of Architecture, GSD',Department:='Other']
# tableManualReg[Department=='D-Lab',Department:='Other']
# tableManualReg[Department=='Past MIT-ETT Fellew',Department:='Other']
# tableManualReg$ProgramYear = '2020-2021'
# tableManualReg[PKGProgram=='Spring PKG Fellowships', ProgramSem:='Spring']
# tableManualReg[PKGProgram=='Spring PKG Fellowships', PKGProgram:='Fellowships']
# tableManualReg[PKGProgram=='Summer PKG Fellowships', ProgramSem:='Summer']
# tableManualReg[PKGProgram=='Summer PKG Fellowships', PKGProgram:='Fellowships']
# tableManualReg[PKGProgram=='Fall PKG Fellowships', ProgramSem:='Fall']
# tableManualReg[PKGProgram=='Fall PKG Fellowships', PKGProgram:='Fellowships']
# tableManualReg[PKGProgram=='IAP PKG Fellowships', ProgramSem:='IAP']
# tableManualReg[PKGProgram=='IAP PKG Fellowships', PKGProgram:='Fellowships']
# 
# tableManualReg[PKGProgram=='UA COVID Training #1', PKGProgram:='UA COVID Training']
# tableManualReg[PKGProgram=='UA COVID Training #2', PKGProgram:='UA COVID Training']
# tableManualReg[PKGProgram=='PPPSC P1', PKGProgramNotes:=paste(PKGProgramNotes,'PPPSC1')]
# tableManualReg[PKGProgram=='PPPSC P1', PKGProgram:='PPPSC']
# tableManualReg[PKGProgram=='PPPSC P2', PKGProgramNotes:=paste(PKGProgramNotes,'PPPSC2')]
# tableManualReg[PKGProgram=='PPPSC P2', PKGProgram:='PPPSC']
# tableManualReg[PKGProgram=='PPPSC P3', PKGProgramNotes:=paste(PKGProgramNotes,'PPPSC3')]
# tableManualReg[PKGProgram=='PPPSC P3', PKGProgram:='PPPSC']
# tableManualReg[PKGProgram=='IDEAS Chat & Chew', PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=='IDEAS IAP Proposal Workshop', PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=='IDEAS Panel', PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=='IDEAS Virtual Generator', PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=='IDEAS T=0 Open House', PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=="IDEAS What's Next Series", PKGProgram:='IDEAS Events']
# tableManualReg[PKGProgram=="Summer Social Impact Internships", ProgramSem:='Summer']
# tableManualReg[PKGProgram=="Summer Social Impact Internships", PKGProgram:='Social Impact Internships']
# 
# tableManualReg[PKGProgram=='COPE Navajo Nation', PKGProgramNotes:=paste(PKGProgramNotes,'COPE Navajo Nation')]
# tableManualReg[PKGProgram=='COPE Navajo Nation', PKGProgram:='COPE']
# tableManualReg[PKGProgram=='COPE Puerto Rico', PKGProgramNotes:=paste(PKGProgramNotes,'COPE Puerto Rico')]
# tableManualReg[PKGProgram=='COPE Puerto Rico', PKGProgram:='COPE']
# tableManualReg[PKGProgram=='Community-Based Federal Work-Study', PKGProgram:='Community Based Federal Work Study']
# 
# tableManualReg[Gender=='he', Gender:='He/His/Him']
# tableManualReg[Gender=='He', Gender:='He/His/Him']
# tableManualReg[Gender=='he/him/his', Gender:='He/His/Him']
# tableManualReg[Gender=='she/her', Gender:='She/Her/Hers']
# tableManualReg[Gender=='she/her/hers', Gender:='She/Her/Hers']
# tableManualReg[Gender=='she series', Gender:='She/Her/Hers']
# tableManualReg[Gender=='she', Gender:='She/Her/Hers']
# tableManualReg[Gender=='', Gender:='No response']
# tableManualReg[,Race:=NULL]
# tableManualReg[,Pipeline:=NULL]
# tableManualReg$Pipeline='No response'
# tableManualReg$Race='No response'
# tableManualReg$FSILG=''
# 
# tableManualReg[MIT_ID=='',MIT_ID:=mapply(getMITID,EmailIn=Email)]
# tableManualReg[GradYear=='',GradYear:=mapply(getGradYear,EmailIn=Email)]
# tableManualReg[,Comments:=as.character(Comments)]
# tableManualReg[,Department2:=NULL]
# tableAllRegistration = rbind(tableAllRegistration,tableManualReg, fill=TRUE)
# tableAllRegistration[is.na(TimeStamp),TimeStamp:=format(Sys.time(), "%m/%d/%Y %H:%M:%S")]
# 
# tableAllRegistration = tableAllRegistration[order(FirstName,LastName,PKGProgram)]
# tableAllRegistration = unique(tableAllRegistration)
# 
# ## Add Unique ID
# tableAllRegistration$UID = 1:length(tableAllRegistration$TimeStamp)
# tableAllRegistration[is.na(Race),Race:='No response']
# tableAllRegistration[is.na(Gender),Gender:='No response']
# tableAllRegistration[is.na(ProgramSem),ProgramSem:='No Data']
# 
# 
# ## Fill in Data when possible and then remove duplicates
# 
# setkeyv(tableAllRegistration, c('FirstName', 'LastName','PKGProgram'))
# dups = duplicated(tableAllRegistration, by = key(tableAllRegistration));
# tableAllRegistration[, Duplicate := dups | c(tail(dups, -1), FALSE)]
# tableAllRegistration_Duplicate = tableAllRegistration[Duplicate==TRUE & FirstName!='',]
# tableAllRegistration_Unique = tableAllRegistration[!UID %in% tableAllRegistration_Duplicate$UID,]
# 
# tableAllRegistration_Duplicate_Copy = copy(tableAllRegistration_Duplicate)
# 
# getMissingRaceDuplicate = function(FN, LN, RaceIn){
#   Race = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$Race)
#   Race = Race[!Race=='No response']
#   Race = Race[!Race=='Other']
#   if(length(Race)==0){
#     if(RaceIn=='Other'){
#       return('Other')
#     }else {
#       return('No response')
#     }
#   }else if(length(Race)==1){
#     return(Race)
#   }else{
#     if(RaceIn=='No response' || is.na(RaceIn) || RaceIn=='Other'){
#       return(Race[1])
#     }else{
#       return(RaceIn)
#     }
#     
#   }
# }
# 
# getMissingGenderDuplicate = function(FN, LN, GenderIn){
#   Gender = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$Gender)
#   Gender = Gender[!Gender=='No response']
#   if(length(Gender)==0){
#     return('No response')
#   }else if(length(Gender)==1){
#     return(Gender)
#   }else{
#     if(GenderIn=='No response' || is.na(GenderIn)){
#       return(Gender[1])
#     }else{
#       return(GenderIn)
#     }
#     
#   }
# }
# 
# getMissingStudTypeDuplicate = function(FN, LN, STIn){
#   ST = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$StudentType)
#   ST = ST[!ST=='No response']
#   ST = ST[!is.na(ST)]
#   ST = ST[ST!='NA']
#   if(length(ST)==0){
#     return('No response')
#   }else if(length(ST)==1){
#     return(ST)
#   }else{
#     if(STIn=='No response' || is.na(STIn) || STIn=='NA'){
#       return(ST[1])
#     }else{
#       return(STIn)
#     }
#   }
# }
# 
# getMissingDepartmentDuplicate = function(FN, LN, DepIn){
#   Dep = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$Department)
#   Dep = Dep[!Dep=='No response']
#   Dep = Dep[!is.na(Dep)]
#   Dep = Dep[!Dep=='Other']
#   if(length(Dep)==0){
#     if(DepIn=='Other'){
#       return('Other')
#     }else {
#       return('No response')
#     }
#   }else if(length(Dep)==1){
#     return(Dep)
#   }else{
#     if(DepIn=='No response' || is.na(DepIn) || DepIn=='Other'){
#       return(Dep[1])
#     }else{
#       return(DepIn)
#     }
#   }
# }
# 
# getMissingMITDuplicate = function(FN, LN, MITIn){
#   MIT = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$MIT_ID)
#   MIT = MIT[!MIT=='']
#   if(length(MIT)==0){
#     return('')
#   }else if(length(MIT)==1){
#     return(MIT)
#   }else{
#     if(MITIn==''){
#       return(MIT[1])
#     }else{
#       return(MITIn)
#     }
#   }
# }
# 
# getMissingEmailDuplicate = function(FN, LN, EmailIn){
#   Email = unique(tableAllRegistration_Duplicate_Copy[FirstName==FN & LastName==LN,]$Email)
#   Email = Email[!Email=='']
#   if(length(Email)==0){
#     return('')
#   }else if(length(Email)==1){
#     return(Email)
#   }else{
#     if(EmailIn==''){
#       return(Email[1])
#     }else{
#       return(EmailIn)
#     }
#   }
# }
# 
# tableAllRegistration_Duplicate[,Race:=mapply(getMissingRaceDuplicate,FN=FirstName,LN=LastName,RaceIn=Race)]
# tableAllRegistration_Duplicate[,Gender:=mapply(getMissingGenderDuplicate,FN=FirstName,LN=LastName,GenderIn=Gender)]
# tableAllRegistration_Duplicate[,StudentType:=mapply(getMissingStudTypeDuplicate,FN=FirstName,LN=LastName,STIn=StudentType)]
# tableAllRegistration_Duplicate[,Department:=mapply(getMissingDepartmentDuplicate,FN=FirstName,LN=LastName,DepIn=Department)]
# tableAllRegistration_Duplicate[,MIT_ID:=mapply(getMissingMITDuplicate,FN=FirstName,LN=LastName,MITIn=MIT_ID)]
# tableAllRegistration_Duplicate[,Email:=mapply(getMissingEmailDuplicate,FN=FirstName,LN=LastName,EmailIn=Email)]
# 
# 
# ### Recombine
# tableFinal = rbind(tableAllRegistration_Unique,tableAllRegistration_Duplicate)
# tableFinal[MIT_ID=='',MIT_ID:=mapply(getMITID,EmailIn = Email)]
# tableFinal[FirstName=='',FirstName:=mapply(getFNEmail,EmailIn=Email)]
# tableFinal[LastName=='',LastName:=mapply(getLNEmail,EmailIn=Email)]
# 
# 
# setkeyv(tableFinal, c('FirstName', 'LastName','PKGProgram','ProgramSem'))
# dups = duplicated(tableFinal, by = key(tableFinal));
# tableFinal[, Duplicate := dups | c(tail(dups, -1), FALSE)]
# tableFinal_Duplicate = tableFinal[Duplicate==TRUE,]
# tableFinal_Unique = tableFinal[!UID %in% tableFinal_Duplicate$UID,]
# 
# tableFinal_Duplicate_Reduced = tableFinal_Duplicate[,lapply(.SD, paste0, collapse=","), by=.(FirstName,LastName,
#                                                                                              PKGProgram,ProgramSem,ProgramYear,StudentType,Race,Gender,MIT_ID,Department,Pipeline,
#                                                                                              Q1_LearnSI, Q1_LearnVS, Q1_LearnSocPol, Q1_LearnLead,Q1_ParticPol,
#                                                                                              Q2_ImpContext,Q2_ImpExp, Q2_ImpSkill, Q2_ImpRes, Q2_ImpNet, Q3_EquipVol,
#                                                                                              Q3_EquipCom, Q3_EquipCareer)]
# 
# getFirstEmail = function(EmailIn){
#   return(strsplit(EmailIn,',')[[1]][1])
# }
# 
# tableFinal_Duplicate_Reduced[,Email:=mapply(getFirstEmail,Email)][,UID:=NULL][,Duplicate:=NULL]
# tableFinal_Unique[,UID:=NULL][,Duplicate:=NULL]
# 
# tableFullFinal = rbind(tableFinal_Unique,tableFinal_Duplicate_Reduced)
# 
# ### Add Unique ID
# tableFullFinal$UID = 1:length(tableFullFinal$TimeStamp)
# 
# ## Final Clean-up
# tableFullFinal[!StudentType %in% c('Undergraduate','Graduate','No response','Other'),StudentType:='Other']
# tableFullFinal[!Gender %in% c('She/Her/Hers','He/His/Him','Other','They/Them','No response'),Gender:='Other']
# tableFullFinal[!Race %in% c('No response','Asian / South Asian American','White / Caucasian American',
#                             'Other','Black / African American','Hispanic / Latinx American'),Race:='Other']
# 
# #### Save Data for backup
# timeString = gsub(" ","_",Sys.time())
# timeString = gsub(":","_",timeString)
# saveRDS(tableFullFinal,file=paste('./processedData/PKG_Registration_Data_',timeString,'.RDS',sep=''))
# saveRDS(tableFullFinal,file=paste('./processedData/PKG_Registration_Data_MostRecent.RDS',sep=''))
# 
# ############################################################################################# Group Programs 
# 
# tableFullFinal[PKGProgram %in% c('ACE FPOP','Active Community Engagement','Active Community Engagement (ACE) FPOP',
#                                  'Active Community Engagement FPOP','Active Community Engagement (ACE)'), PKGProgram:='ACE']
# tableFullFinal[PKGProgram %in% c('Community-Informed Field Immersion','Community-Informed Field Immersion (CIFI)','COPE'), PKGProgram:='CIFI']
# tableFullFinal[PKGProgram %in% c('Summer Immersion: PKG Connect','PKG Connect'), PKGProgram:='Connect']
# tableFullFinal[PKGProgram %in% c('Community Based Federal Work Study','Work study'), PKGProgram:='Work Study']
# tableFullFinal[PKGProgram %in% c('DUSP-PKG Fellowships'), PKGProgram:='Fellowships']
# tableFullFinal[PKGProgram %in% c('Social Impact Internships','AAPIP (Internship host)'), PKGProgram:='Internships']
# tableFullFinal[PKGProgram %in% c('General PKG Workshop / Training','PKG Co-facilitated Workshop','PKG Community Partner Engagement',
#                                  'PKG Content Based Workshop','PKG Information Session','PPPSC','Orientation Training'), PKGProgram:='Workshops']
# tableFullFinal[PKGProgram %in% c('ACE Intensive - ELO','IDEAS ELO'), PKGProgram:='One-time ELO']
# tableFullFinal[PKGProgram %like% "ELO", PKGProgram:='One-time ELO']



###############################################################
#### Old Code for Handling Legacy Completion Data 
###############################################################

# 
# tableComplete[PKGProgram=='Community-Informed Field Immersion (CIFI) - Fall ELO',PKGProgram:='Community-Informed Field Immersion']
# tableComplete[PKGProgram=='SP.251 How to Change the World: Experiences from Social Entrepreneurs (In partnership with SOLVE)',PKGProgram:='SP.251']
# tableComplete[PKGProgram=='ACE Intensive (Fall-ELO)',PKGProgram:='ACE Intensive - ELO']
# tableComplete[PKGProgram=='Fellowships Program',PKGProgram:='Fellowships']
# tableComplete[PKGProgram=='Social Impact Internships and Employment',PKGProgram:='Social Impact Internships']
# tableComplete[PKGProgram=='Community-Based Federal Work-Study',PKGProgram:='Community Based Federal Work Study']
# 
# tableComplete[, ProgramYear:=as.character(ProgramYear)]
# tableComplete[ProgramYear=='',ProgramYear:=mapply(getAcademicYear,TimeStamp)]
# tableComplete[, ProgramYear:=as.character(ProgramYear)]
# 
# tableComplete[PKGProgram=='ACE Intensive - ELO' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[PKGProgram=='IDEAS ELO' & ProgramSem=='',ProgramSem:='IAP']
# tableComplete[PKGProgram=='IDEAS' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[PKGProgram=='Fellowships' & ProgramSem=='',ProgramSem:='Spring']
# tableComplete[PKGProgram=='Community-Informed Field Immersion' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[PKGProgram=='Social Impact Internships and Employment' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[PKGProgram=='PKG IAP: Health' & ProgramSem=='',ProgramSem:='IAP']
# tableComplete[PKGProgram=='Civic Engagement and Voting' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[PKGProgram=='SP.251' & ProgramSem=='',ProgramSem:='Fall']
# tableComplete[ProgramSem == '',ProgramSem:='No Data']
# 
# 
# 
# tableComplete = data.table(tableComplete)
# 
# tableComplete[FirstName=='',FirstName:=mapply(getFN,MIT_ID)]
# tableComplete[LastName=='',LastName:=mapply(getLN,MIT_ID)]
# tableComplete[,Race:=mapply(getRace,MIT_ID)]
# tableComplete[,Gender:=mapply(getGender,MIT_ID)]
# tableComplete[StudentType=='',StudentType:=mapply(getStudentType,MIT_ID)]
# tableComplete[Department=='',Department:=mapply(getDepartment,MIT_ID)]
# 
# 
# ############################################################################################# Group Programs 
# 
# 
# tableComplete[PKGProgram %in% c('ACE FPOP','Active Community Engagement','Active Community Engagement (ACE) FPOP',
#                                 'Active Community Engagement FPOP','Active Community Engagement (ACE)'), PKGProgram:='ACE']
# tableComplete[PKGProgram %in% c('Community-Informed Field Immersion','Community-Informed Field Immersion (CIFI)','COPE'), PKGProgram:='CIFI']
# tableComplete[PKGProgram %in% c('Summer Immersion: PKG Connect','PKG Connect'), PKGProgram:='Connect']
# tableComplete[PKGProgram %in% c('Community Based Federal Work Study','Work study'), PKGProgram:='Work Study']
# tableComplete[PKGProgram %in% c('DUSP-PKG Fellowships'), PKGProgram:='Fellowships']
# tableComplete[PKGProgram %in% c('Social Impact Internships','AAPIP (Internship host)'), PKGProgram:='Internships']
# tableComplete[PKGProgram %in% c('General PKG Workshop / Training','PKG Co-facilitated Workshop','PKG Community Partner Engagement',
#                                 'PKG Content Based Workshop','PKG Information Session','PPPSC','Orientation Training'), PKGProgram:='Workshops']
# tableComplete[PKGProgram %in% c('ACE Intensive - ELO','IDEAS ELO'), PKGProgram:='One-time ELO']
# tableComplete[PKGProgram %like% "ELO", PKGProgram:='One-time ELO']
# tableComplete[PKGProgram=='AAPIP',PKGProgram:='Social Impact Internships']

