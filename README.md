# VShred

![Build Status](https://github.com/bstnbuck/VShred/workflows/VShred/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/bstnbuck/VShred/blob/main/LICENSE)

> A simple tool to securely delete files and directories, implemented in V.

## Requirements
- Installed [V-Compiler](https://github.com/vlang/v)
- When using `-gc boehm` install `libgc-dev` on Linux => `apt install libgc-dev`

## Usage
* Clone the repository: ```git clone https://github.com/bstnbuck/VShred.git``` 
* Compile the source code with: ```v -gc boehm -cc [tcc][msvc][gcc] -prod vshred.v ``` 
* Run it: ```vshred [--dir] [--dir_name "dir-name"] [--file_name "file-name"] [--rounds some-int] ```

## What it is and how to use it
VShred is a simple tool to safely delete files and entire directories. 
The installed removal tools in Windows and Linux (e.g. rm) only delete the connection to the OS, but not the content. 
This tool writes random content to the file and that several times. After that the file will be renamed and deleted so the file can no longer be reconstructed. 

> Attention, since V´s `autofree` is in an early stage the option `-gc boehm` is highly recommended.

### Usage
Options:
* --dir                    
    * secure delete whole directory
*  --dir_name "string"       
    * name of the directory, which should be recursively shredded. No empty directories! Needs `--dir` flag.
*  --file_name "string"      
    * secure delete a file
*  --rounds \<some-int>            
    * define how often the file should be overridden
*  --help -h
    * show help
