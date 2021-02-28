# VShred

> A simple tool to securely delete files and directorys, implemented in V.

## Requirements
- Installed [V-Compiler](https://github.com/vlang/v)

## Usage
* Clone the repository: ```git clone https://github.com/bstnbuck/VShred.git``` 
* Compile the source code with: ```v -autofree -cc [tcc][msvc][gcc] -prod vshred.v ``` 
* Run it: ```vshred [--dir] [--dir_name "dir-name"] [file_name "file-name"] [--rounds some-int] ```

## What it is and how to use it
VShred is a simple tool to safely delete files and entire directories. 
The installed removal tools in Windows and Linux (e.g. rm) only delete the connection to the OS, but not the content. 
This tool writes a random content to the file and that several times. After that the file is deleted. After that, the file can no longer be reconstructed. 

> Attention, since V is in an early stage, the memory consumption should be monitored.

### Usage
Options:
* --dir (boolean)                     
    * secure delete whole directory
*  --dir_name "string"       
    * name of the directory, which should be recursively shredded. No empty directories!
*  --file_name "string"      
    * secure delete a file
*  --rounds some-int            
    * define how often the file should be overridden
