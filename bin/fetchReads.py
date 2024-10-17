#!/usr/bin/env python3

import os
import sys
from glob import glob

# Get path to directory containing read files
read_dir = os.path.abspath(str(sys.argv[1]))
if not os.path.isdir(read_dir):
    sys.exit("read_dir (Arg 1) - is not a valid path: "+ str(read_dir) )

# Get read filetype information
read_filetype = str(sys.argv[2])
if not read_filetype.startswith("."):
    read_filetype = "." + str(sys.argv[2])
forward_suffix = str(sys.argv[3])
reverse_suffix = str(sys.argv[4])
trim_name = str(sys.argv[5])

# Check if sequence files exist in directory, ignoring undetermined reads
read_files = sorted(glob(read_dir+"/*"+read_filetype))
read_files = [r for r in read_files if not os.path.basename(r).startswith("Undetermined_")]

if len(read_files) == 0:
    sys.exit("No "+read_filetype +" files detected in "+read_dir)

# Get data for paired-end and single-end reads
left_files = [s for s in read_files if s.endswith(forward_suffix)]
right_files = [s for s in read_files if s.endswith(reverse_suffix)]

# Identify pairs based on file name
left_pairs = list()
right_pairs = list()
paired_files = list(set([x.replace(forward_suffix, '') for x in left_files]).intersection([y.replace(reverse_suffix, '') for y in right_files]))

for pair in paired_files:
    left_pairs.append(pair+forward_suffix)
    right_pairs.append(pair+reverse_suffix)
single_end = [x for x in read_files if x not in left_pairs + right_pairs]

for left in left_pairs:
    base = str(os.path.basename(left).replace(forward_suffix,"").replace(trim_name,""))
    print(",".join([base,"Paired",";".join([left,left.replace(forward_suffix,reverse_suffix)])]))

for single in single_end:
    if single.endswith(forward_suffix):
        base = str(os.path.basename(single).replace(forward_suffix,"").replace(trim_name,""))
    else:
        base = str(os.path.basename(single).replace(read_filetype,"").replace(trim_name,""))
    print(",".join([base,"Single",single]))
