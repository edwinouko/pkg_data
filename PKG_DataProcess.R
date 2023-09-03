rm(list=ls())
setwd("~/Desktop/PKGData")
library(data.table)

############################################################################
####  Download Updated Google Form Data and save in ./csvData 
############################################################################
# Registration - 
# Completion - 


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

table[Race=='',Race:='No response']
table[,RaceNotes:=Race]

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

stuffDB <- dbConnect(MariaDB(), user = db_user, password = db_password, dbname = db_name, host = db_host)

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
