#!/usr/bin/python3
import sys

name="server.log"

if len(sys.argv) > 1:
    name=sys.argv[1]

# Open a file
with open(name, "r+") as fin, open(name+".min", "w") as fout:
    for l in fin.readlines():
        if '[' in l and ']' in l:
            l = l[:l.find('[')+1] + l[l.find(']'):]
        fout.write(l)

