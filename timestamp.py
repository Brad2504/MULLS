import argparse

def sum_values_in_file(input_filename, output_filename):
    try:
        # Open the input file for reading
        with open(input_filename, 'r') as infile:
            # Open the output file for writing
            with open(output_filename, 'w') as outfile:
                # Iterate through each line in the input file
                for line in infile:
                    # Strip leading/trailing whitespace
                    line = line.strip()

                    # Split the line into words (assuming values are separated by spaces)
                    numbers = line.split()

                    # Convert each value to a float and sum them
                    try:
                        total_sum = sum(float(num) for num in numbers)
                        # Write the sum to the output file
                        outfile.write(f"{total_sum}\n")
                    except ValueError:
                        outfile.write("Error: Non-numeric value encountered in line\n")

        print(f"Sum of values written to {output_filename}")

    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Set up the argument parser
def parse_arguments():
    parser = argparse.ArgumentParser(description='Sum values from a file and write the results to another file.')
    parser.add_argument('input_filename', type=str, help='The name of the input file to read values from')
    parser.add_argument('output_filename', type=str, help='The name of the output file to write results to')
    return parser.parse_args()

if __name__ == "__main__":
    # Parse the command-line arguments
    args = parse_arguments()

    # Call the function with the input and output filenames
    sum_values_in_file(args.input_filename, args.output_filename)

