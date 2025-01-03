# VShred

![Build Status](https://github.com/bstnbuck/VShred/workflows/VShred/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/bstnbuck/VShred/blob/main/LICENSE)

> A simple tool to securely delete files and directories, implemented in V.

## Requirements
- Installed [V-Compiler](https://github.com/vlang/v)

## Usage
* Clone the repository: ```git clone https://github.com/bstnbuck/VShred.git``` 
* Compile the source code with: ```v -cc [tcc][msvc][gcc] -prod vshred.v ``` 
* Run it: ```vshred [--dir] [-d] [--rounds int] [-r int] [--continue] [--no_output] [-s] [--yes] [-y] <file or directory>```

## What it is and how to use it
VShred is a simple tool to safely delete files and entire directories. 
The installed removal tools in Windows and Linux (e.g. rm) only delete the connection to the OS, but not the content. 
This tool writes random content to the file and that several times. After that the file will be renamed and deleted so the file can no longer be reconstructed. 

### Usage
Options:
* `--dir` `-d`             
    * secure delete whole directory
*  `--rounds` `-r` \<some-int>            
    * define how often the file should be overridden
* `--continue`
    * continue if an error occurs
* `--no_output` `-s`
    * show less output
* `--yes` `-y`
    * no checkbacks
*  `--help` `-h`
    * show help
