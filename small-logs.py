#!/usr/bin/python3
import sys

# Open a file
with open("server.log", "r+") as fin, open("server.log.min", "w") as fout:
    for l in fin.readlines():
        if '[' in l and ']' in l:
            l = l[:l.find('[')+1] + l[l.find(']'):]
        fout.write(l)

