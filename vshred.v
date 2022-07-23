import rand
import os
import flag

const (
	// 1MB
	buffersize = 1048576
)

struct Options {
	no_stop   bool
	no_output bool
	yes       bool
}

fn shred_dir(dir string, rounds int, options Options) bool {
	println('Shredding directory...')

	// get files to delete
	files := make_files_list(os.real_path(dir), options)
	if !options.no_output {
		println('[file-list begin]')
		for file in files {
			println(file)
		}
		println('[file-list end]')
	}

	if !options.yes {
		if os.input('Shredding files now. Okay? (y/n): ') != 'y' {
			println('Abort!')
			return false
		}
	}

	mut enc_files := []string{}
	for file in files {
		new_fname := os.dir(file) + os.path_separator + rand.string(12)
		os.mv(file, new_fname) or {
			println('\tError while renaming file: ' + os.file_name(file))
			println('\tError message: ' + err.msg())
			return false
		}
		enc_files << new_fname
	}

	// remove file for file
	for i, file in enc_files {
		if !options.no_output {
			println('Next file: ' + os.file_name(files[i]))
			println('Shredding file... ' + files[i])
		}

		shred_file(file, rounds, options) or {
			println('\tError while shredding file: ' + os.file_name(files[i]))
			println(err.msg())
			if !options.no_stop {
				return false
			}
			if options.no_output {
				println('')
			}
		}
		if !options.no_output {
			println('Completed!\n')
		}
	}
	os.rmdir_all(os.real_path(dir)) or {
		println('\tError while removing directory: ' + err.msg())
		return false
	}
	println('Removed directory successfull')
	return true
}

fn make_files_list(dir string, options Options) []string {
	if !options.no_output {
		println('Entering dir: ' + dir)
	}

	dir_content := os.ls(dir) or { [] }
	mut files := []string{}

	for content in dir_content {
		fpath := os.join_path(dir, content)
		if os.is_link(fpath) {
			continue
		}
		if os.is_dir(fpath) {
			files << make_files_list(fpath, options)
		} else {
			files << fpath
		}
	}
	return files
}

fn shred_file(file_str string, rounds int, options Options) ? {
	file := os.real_path(file_str)
	file_len := os.file_size(file)

	if os.is_link(file_str) {
		return
	}
	if file_len > 0 {
		mut i := 1
		mut f := os.create(file) or { // binary write mode
			return error('\tCould not open file: $file\n\tError message: ' + err.msg())
		}

		mut file_len_temp := u64(0)

		if !options.no_output {
			print('Shred rounds $rounds => Working round: ')
		}
		for i <= rounds {
			if !options.no_output {
				print('$i ')
			}
			for {
				// use buffersize for byte array length
				if (file_len_temp + buffersize) <= file_len && file_len > buffersize {
					if i != rounds {
						mut random_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. buffersize {
							random_bytes << rand.u8()
						}
						f.write_to(file_len_temp, random_bytes)?
					} else {
						mut nulls_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. buffersize {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes)?
					}
					file_len_temp += buffersize
				} else {
					if i != rounds {
						mut random_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. file_len - file_len_temp {
							random_bytes << rand.u8()
						}
						f.write_to(file_len_temp, random_bytes)?
					} else {
						mut nulls_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. file_len - file_len_temp {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes)?
					}
					file_len_temp = 0
					break
				}
			}
			i++
		}
		f.close()
		if !options.no_output {
			println('Done')
		}
	}
	if !options.no_output {
		print('Removing File... ')
	}

	// remove file
	os.rm(file) or { return error('\tCould not remove file: ' + err.msg()) }
	if !options.no_output {
		println('Done!')
	}
}

fn main() {
	// set flags
	mut fp := flag.new_flag_parser(os.args)
	fp.application('VShred (Securely delete files)')
	fp.version('v1.3.0')
	fp.description('VShred securely delete files, you do not need anymore. Files will be written with random and zero bytes')
	whole_dir := fp.bool('dir', `d`, false, 'secure delete whole directory')
	dir_name := fp.string('dir_name', 0, '', 'name of directory, which should be shred. No empty directories!')
	file_name := fp.string('file_name', 0, '', 'secure delete a file')
	rounds := fp.int('rounds', 0, 5, 'define how often the file should be overridden (> 0)')
	no_stop := fp.bool('continue', 0, false, 'continue if an error occurs')
	no_output := fp.bool('no_output', 0, false, 'show less output')
	yes := fp.bool('yes', `y`, false, 'no checkbacks')

	_ := fp.finalize() or {
		println(fp.usage())
		return
	}

	options := Options{no_stop, no_output, yes}

	println('VShred -- secure delete files!')

	// check if flags correct set
	if whole_dir && os.is_dir(dir_name) && !os.is_dir_empty(dir_name) && rounds > 0 {
		if !shred_dir(dir_name, rounds, options) {
			println('Something went wrong... => See error messages above')
			return
		}
		println('Success! Deleted directory: ' + dir_name)
	} else if !whole_dir && os.is_file(file_name) && rounds > 0 {
		new_fname := os.dir(os.real_path(file_name)) + os.path_separator + rand.string(12)
		os.mv(file_name, new_fname)?
		if !options.no_output {
			println('Shredding file... ' + os.file_name(file_name))
		}
		shred_file(new_fname, rounds, options) or {
			println('Something went wrong...')
			println('\tError message: ' + err.msg())
			return
		}
		println('Success! Shredded file: ' + file_name)
	} else {
		println('Flags incorrect!')
		if !whole_dir && dir_name == '' && os.is_dir(file_name) {
			println('Hint: \'$file_name\' is a directory.')
		}
		println("Maybe there is a typo, the file/dir does not exist or 'rounds' is lower 1\n")
		if os.input('Show usage? (y/n) ') == 'y' {
			println(fp.usage())
		}
	}
	println('Bye!')
}
