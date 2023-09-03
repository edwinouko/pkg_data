import pandas as pd
csv_file = "PKG Student Registration (Responses) - Form Responses 1.csv"
df = pd.read_csv(csv_file)
#change the names of columns
map_dic = {"MIT ID (Enter 0 if no ID)": "MIT ID", 
           "Primary Department": "Department",
           "Graduation Year (YYYY) ": "Graduation Year (YYYY)",
           "Graduation Year (YYYY) - Enter 0 if not applicable": "Graduation Year (YYYY)"}
for c in df.columns: #renaming columns
    if c in map_dic:
        df.rename(columns={c: map_dic[c]}, inplace=True)

#save the new csv file
df.to_csv("PKG Student Registration (Responses) - Form Responses 1.csv", index=False)

            