import pandas as pd
exit_survey = pd.read_csv('PKG Program Exit Survey (Responses) - Form Responses 1.csv')
old_completion_survey = pd.read_csv("PKG Program Completion (Responses) - Form Responses 1.csv")
shared_columns_dic = {}
old_completion_survey_shared_columns_names = ["Timestamp", "MIT ID", "MIT Email", "Your program should be preselected, please confirm and continue", 
                                             "Select the term in which you began the program", "Select the academic year in which you began the program"]
exit_survey_shared_columns_names = ["Timestamp", "MIT ID (enter 0 if no ID)", "Email (MIT Preferred)", "Your program should be preselected, please confirm and continue.",
                                        "Select the term in which you began the program.", "Select the academic year in which you began the program."]
for i in range(len(old_completion_survey_shared_columns_names)):
    shared_columns_dic[exit_survey_shared_columns_names[i]] = old_completion_survey_shared_columns_names[i]

final_exit_survey_columns = old_completion_survey.columns.tolist()
for col in exit_survey.columns:
    if col not in shared_columns_dic:
        final_exit_survey_columns.append(col)

exit_survey.rename(columns=shared_columns_dic, inplace=True)
for col in final_exit_survey_columns:
    if col in old_completion_survey.columns and col not in shared_columns_dic.values():
        exit_survey[col] = [""] * len(exit_survey)

exit_survey.to_csv("PKG Program Exit Survey (Responses) - Form Responses 1.csv", index=False)