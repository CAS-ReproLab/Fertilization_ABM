'''
file_correction.py
This file filters through csv files generated by Netlogo Simulation from a directory and corrects the ones where two
simulations were generated into one csv file instead of just one simulation.
Created By: Kylie C
'''

import pandas as pd
import os
import sys

def process_csv_files(directory):
    # Iterate through all files in the given directory
    for filename in os.listdir(directory):
        if filename.endswith(".csv"):
            file_path = os.path.join(directory, filename)

            # Load the CSV file into a DataFrame
            df = pd.read_csv(file_path)

            # Check the number of rows in the DataFrame
            num_rows = df.shape[0]

            if num_rows == 200:
                print(f"File {filename} has 201 rows.")
            elif num_rows == 401:
                print(f"File {filename} has 402 rows, splitting...")

                # Split the DataFrame into two parts
                first_half = df.iloc[:200]
                second_half = df.iloc[200:]

                # Save the first half to the original file (overwrites the file)
                first_half.to_csv(file_path, index=False)

                # Save the second half to a new file with '-5' appended to the original filename
                new_filename = os.path.splitext(filename)[0] + "_2.csv"
                new_file_path = os.path.join(directory, new_filename)
                second_half.to_csv(new_file_path, index=False)
                print(f"Created {new_filename}.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script_name.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    process_csv_files(directory)
    print(directory, " complete")
