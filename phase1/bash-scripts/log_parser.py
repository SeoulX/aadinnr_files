# log_parser.py
filename = "hello.log"
count = 0

with open(filename, "r") as f:
    for line in f:
        if "ERROR" in line:
            count += 1

print(f"Total ERRORs found: {count}")
