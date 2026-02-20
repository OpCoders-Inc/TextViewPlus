#! /usr/bin/env python3

"""
    Standalone make script written
    in Python. There are no other packages
    needed to run it other than plain vanilla
    Python. 

    Requires Python 3.4+

    USAGE

    make.py [--final]

    The script can be run on its own, in which case it will create
    a developer build. 

    There is one optional argument for `make.py`:
    - `--final` will prepare the `msg.txt` and `about.txt` for the final
      release. Leaving it blank will provide helpful information for
      the user to give to the developer.

"""

import os
import pathlib
import datetime
import subprocess
import sys

VERSION = "1.2-dev"
MAKE_OPTION = "none"
AUTHOR = "Paul Hocker"

# increase build number

buildnumber_file = ".build"
buildnumber = 0
builddate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

with open(buildnumber_file, "r", encoding=None) as f:

    data = f.read()
    buildnumber = int(data)

buildnumber += 1

with open(buildnumber_file, "w", encoding=None) as f:
    f.write(str(buildnumber))

# developer build settings

MSG = f"v{VERSION} Build {buildnumber} on {builddate}"
ABOUT = f"TextView+\n{VERSION}\n2025\n{buildnumber}\n"

print(f"Build number {buildnumber}")

if "--final" in sys.argv:

    print("Updating ABOUT and MSG for final build")

    MSG = " If you don't like to read, you haven't  found the right book! - J.K Rowling"
    ABOUT = f"TextView+\n{VERSION}\n2025\n{AUTHOR}\n"

message_file = "msg.txt"
with open(message_file, "w", encoding=None) as f:
    f.write(MSG)

about_file = "about.txt"
with open(about_file, "w", encoding=None) as f:
   f.write(ABOUT)

