'''
combine_columns.py
This file retrieves all the result csv files generated from simulation.py from a directory and combines
them into four csv files for all the Q', Likelihood, and Posterior results.
'''

import csv
import os
import sys
from itertools import zip_longest


def fill_missing_rows(data):
    '''
    This function fills missing rows with zeros based on frequency column.
    Ensures that frequencies start from 0 and fills up to the max frequency found.
    '''

    if not data:
        return []

    # Convert the frequency from float strings to integers and find min and max frequencies
    freqs = [int(float(row[0])) for row in data]
    max_freq = max(freqs)

    filled_data = []
    data_iter = iter(data)
    current_row = next(data_iter, None)

    # Fill from 0 up to max_freq ensuring all frequencies are accounted for
    for expected_freq in range(max_freq + 1):
        if current_row and int(float(current_row[0])) == expected_freq:
            filled_data.append(current_row)
            current_row = next(data_iter, None)
        else:
            # Fill the missing frequency rows with zeros
            filled_data.append([str(expected_freq)] + ['0'] * (len(data[0]) - 1))

    return filled_data


def combine_columns(directory):
    '''
    This function aggregates specific columns from multiple CSV files in a directory, combining the data into
    new CSV files for each column
    '''

    # Indices for the columns to combine from the CSV files
    indices = {
        'Q': 1,
        'likelihood': 2,
        'posterior': 3
    }

    # Initialize a dictionary to hold combined data for each column type
    combined_data = {key: [] for key in indices}
    filenames = []

    # Iterate over each file in the specified directory
    for filename in os.listdir(directory):
        # Process only files ending with "_results.csv"
        if filename.endswith("_results.csv"):
            filepath = os.path.join(directory, filename)
            filenames.append(filename)
            with open(filepath, newline='') as csvfile:
                reader = csv.reader(csvfile)
                next(reader)  # Skip header
                original_data = [row for row in reader]
                data = fill_missing_rows(original_data)  # Fill missing rows if necessary
                columns = list(zip(*data))  # Transpose rows to columns

                # Extract and store data for each specified column
                for key, index in indices.items():
                    column_data = columns[index]
                    combined_data[key].append(column_data)

    # Write the combined data to new CSV files for each column type
    for key, data in combined_data.items():
        output_filename = os.path.join(directory, f"{os.path.basename(directory)}_{key}.csv")
        with open(output_filename, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(filenames)  # Write filenames as header
            for row in zip_longest(*data, fillvalue=''):  # Combine rows from different files
                writer.writerow(row)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    combine_columns(directory)
    print("Files have been successfully created.")
