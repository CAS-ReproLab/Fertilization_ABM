'''
combine_kl_columns.py
This file retrieves all the result csv files generated from simulation.py from a directory and combines
them into a csv file for all KL Divergence results.
'''

import os
import sys
import csv


def extract_kl_divergence(directory):
    """Extracts the KL Divergence column from all CSV files in the specified directory."""
    kl_data = []  # List to store all KL Divergence data
    filenames = []  # List to store the names of the files

    # Loop through all files in the directory
    for filename in os.listdir(directory):
        if filename.endswith("_results.csv"):
            filepath = os.path.join(directory, filename)
            filenames.append(filename)
            file_kl_data = []
            try:
                with open(filepath, newline='') as csvfile:
                    reader = csv.reader(csvfile)
                    header = next(reader, None)  # Skip the header
                    kl_index = header.index("KL Divergence") if "KL Divergence" in header else -1
                    if kl_index != -1:
                        for row in reader:
                            kl_value = row[kl_index] if len(row) > kl_index and row[kl_index].strip() else ''
                            file_kl_data.append(kl_value)
                    kl_data.append(file_kl_data)
            except Exception as e:
                print(f"Failed to process {filename}: {e}")

    # Prepare to write the extracted data
    output_filename = os.path.join(directory, f"{os.path.basename(directory)}_kl_divergence.csv")
    max_length = max(len(data) for data in kl_data) if kl_data else 0

    with open(output_filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(filenames)  # Write the filenames as headers

        # Writing data by rows with proper alignment
        for i in range(max_length):
            row = [(kl_data[j][i] if i < len(kl_data[j]) else '') for j in range(len(kl_data))]
            writer.writerow(row)

    print(f"KL divergence data has been successfully exported to {output_filename}.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    extract_kl_divergence(directory)
