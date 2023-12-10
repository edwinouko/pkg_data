import pandas as pd

cf = pd.read_csv("PKG Program Completion (Responses) - Form Responses 1.csv")
combined_cols = [i for i in cf.columns[:26]]

es = pd.read_csv("PKG Program Exit Survey (Responses) - Form Responses 1.csv")
other_cols = [ i for i in es.columns[10:19]] + [es.columns[21]]
combined_cols += other_cols
map_dic = {"MIT ID (enter 0 if no ID)": "MIT ID", "Email (MIT Preferred)": "MIT Email", "Primary Department": "Department",
            "Your program should be preselected, please confirm and continue.": "Your program should be preselected, please confirm and continue",
            "Select the academic year in which you began the program.": "Select the academic year in which you began the program", 
            "Select the term in which you began the program.": "Select the term in which you began the program",
            "Please share any additional feedback about your accomplishments, frustrations, learnings, and anything else you'd like us to know.":
            "Please provide a sentence or two telling us about your accomplishments, frustrations and learnings. We'd love to know how this experience has impacted your interests going forward and your opinions on service and social impact.",
            "The PKG Center occasionally hosts events for the MIT community and supporters of the Center. Would you be willing to speak about your PKG experience?":
            "The PKG Center occasionally does events for the MIT community and supporters of the Center. Would you be willing to speak about your PKG programmatic experience?"
            }

combined_df = pd.DataFrame(columns=combined_cols)
for c in es.columns: #renaming columns
    if c in map_dic:
        es.rename(columns={c: map_dic[c]}, inplace=True)

for i in range(len(es)):
    row = {}
    for col in combined_df.columns:
        if col in es.columns:
            row[col] = es[col][i]
        else:
            row[col] = ""
    combined_df = combined_df.append(row, ignore_index=True)

combined_df.to_csv("combined_completion.csv", index=False)



