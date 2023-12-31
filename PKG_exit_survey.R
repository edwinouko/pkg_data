##
#* Date of last update: 09/02/2023 23:20
#* Form the exit-survey-responses, filter for responses after the date above and download as csv into the same folder as this file
#* Run preprocess_exit_survey.py to generate combined_completion.csv which is used to update the database
#* Append the new responses to the database by running this file


rm(list=ls())
#set origin using setwd() or cd into the right directory
library(data.table)

#Merge demographic data from Final Registration Table
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

tableComplete = data.table(read.csv('./csvData/combined_completion.csv'))

#### Subset table for General Values that are common across all programs
#completionNames = readRDS(file='./supportData/CompletionTable_Names.RDS')
completionNames = names(tableComplete)

newCols = c('TimeStamp','MIT_ID','Email','PKGProgram','LearningFeedback',
            'Q1Contribute_SI','Q1Contribute_USC','Q1Contribute_Skill','Q1Contribute_Network','Q1Contribute_Res',
            'Q2Interest_Context','Q2Interest_USC','Q2Interest_Skill','Q2Interest_Res','Q2Interest_Network',
            'Q3Equip_Vol','Q3Equip_Community','Q3Equip_Career','PKG_Ambassador','OptionalFeedback','ProgramSem','ProgramYear',
            'FirstName','LastName','StudentType','Department', "better_understanding_agree", "effect_understanding_social_issues", "gain_skills_social_change_agree", 
            "confidence_influencing_social_change_agree", "effect_confidence_influencing_social_change", "inspired_knowledge_forsocial_change_agree",
            "incorporate_social_change_effort_academics_agree", "incorporate_social_change_effort_career_agree", "effect_motivation_social_change", 
            "associate_name_feedback")
setnames(tableComplete,completionNames,newCols)
                        
tableComplete = tableComplete[,newCols,with=F]  
tableComplete[,Race:=mapply(getRace,MIT_ID)]
tableComplete[,Gender:=mapply(getGender,MIT_ID)]


# tableLegacy = readRDS(file='./csvData/PKG_Completion_Data_Legacy_5_8_2022.RDS')
# #Add the additional columns to the legacy data

# tableLegacy = tableLegacy[,  `:=` (better_understanding_agree=NA, effect_understanding_social_issues=NA, gain_skills_social_change_agree=NA, 
#             confidence_influencing_social_change_agree=NA, effect_confidence_influencing_social_change=NA, inspired_knowledge_forsocial_change_agree=NA,
#             incorporate_social_change_effort_academics_agree=NA, incorporate_social_change_effort_career_agree=NA, effect_motivation_social_change=NA, 
#             associate_name_feedback=NA)]

# # ### Merge Old and New Data
# tableComplete = rbind(tableLegacy,tableComplete)
# tableComplete[,Race:=unlist(Race)]
# tableComplete[,Gender:=unlist(Gender)]

### QA - QC
tableComplete[PKGProgram=='SP.251',PKGProgram:='SP.251 How to Change the World: Experiences from Social Entrepreneurs (In partnership with SOLVE)']
tableComplete[PKGProgram=='SP.250',PKGProgram:='SP.250 Transforming Good Intentions into Good Outcomes']
tableComplete[PKGProgram=='Fellowships',PKGProgram:='PKG Fellowships Program']
tableComplete[PKGProgram=='Fellowships',PKGProgram:='DUSP Fellowships Program']
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

stuffDB <- dbConnect(MariaDB(), user = db_user, password = db_password, dbname = db_name, host = db_host)

# Write to Database
dbWriteTable(stuffDB, value = tableComplete, row.names = FALSE, name = db_table, overwrite = FALSE, append=TRUE)

#Close connection
dbDisconnect(stuffDB)
