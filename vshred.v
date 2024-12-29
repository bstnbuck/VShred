import rand
import os
import flag

// 1MB
const buffersize = 1048576

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

fn shred_file(file_str string, rounds int, options Options) ! {
	file := os.real_path(file_str)
	file_len := os.file_size(file)

	if os.is_link(file_str) {
		return
	}
	if file_len > 0 {
		mut i := 1
		mut f := os.create(file) or { // binary write mode
			return error('\tCould not open file: ${file}\n\tError message: ' + err.msg())
		}

		mut file_len_temp := u64(0)

		if !options.no_output {
			print('Shred rounds ${rounds} => Working round: ')
			flush_stdout()
		}
		for i <= rounds {
			if !options.no_output {
				print('${i} ')
				flush_stdout()
			}
			for {
				// use buffersize for byte array length
				if (file_len_temp + buffersize) <= file_len && file_len > buffersize {
					if i != rounds {
						mut random_bytes := []u8{}

						// create new output as random byte array of buffer size
						for _ in 0 .. buffersize {
							random_bytes << rand.u8()
						}
						f.write_to(file_len_temp, random_bytes)!
					} else {
						mut nulls_bytes := []u8{}

						// create new output as null byte array of buffer size
						for _ in 0 .. buffersize {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes)!
					}
					file_len_temp += buffersize
				} else {
					if i != rounds {
						mut random_bytes := []u8{}

						// create new output as random byte array of remaining size
						for _ in 0 .. file_len - file_len_temp {
							random_bytes << rand.u8()
						}
						f.write_to(file_len_temp, random_bytes)!
					} else {
						mut nulls_bytes := []u8{}

						// create new output as null byte array of remaining size
						for _ in 0 .. file_len - file_len_temp {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes)!
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
			flush_stdout()
		}
	}
	if !options.no_output {
		print('Removing File... ')
		flush_stdout()
	}

	// remove file
	os.rm(file) or { return error('\tCould not remove file: ' + err.msg()) }
	if !options.no_output {
		println('Done!')
		flush_stdout()
	}
}

fn main() {
	// set flags
	mut fp := flag.new_flag_parser(os.args)
	fp.application('VShred (Securely delete files)')
	fp.version('v1.4.0')
	fp.description('VShred securely delete files, you do not need anymore. Files will be written with random and zero bytes.')
	fp.skip_executable()
	whole_dir := fp.bool('dir', `d`, false, 'secure delete whole directory')
	rounds := fp.int('rounds', `r`, 5, 'define how often the file should be overridden (> 0)')
	no_stop := fp.bool('continue', 0, false, 'continue if an error occurs')
	no_output := fp.bool('no_output', `s`, false, 'show less output')
	yes := fp.bool('yes', `y`, false, 'no checkbacks')

	fp.arguments_description('<file or directory>')
	fp.usage_example('./vshred -d -r <rounds> <dir or file>')

	elem := fp.finalize() or {
		println(fp.usage())
		return
	}
	dir_or_file := if elem.len != 0 { elem[0] } else { '' }

	options := Options{no_stop, no_output, yes}

	println('VShred -- secure delete files!')

	// check if flags correct set
	if whole_dir && os.is_dir(dir_or_file) && !os.is_dir_empty(dir_or_file) && rounds > 0 {
		if !shred_dir(dir_or_file, rounds, options) {
			println('Something went wrong... => See error messages above')
			return
		} else {
			println('Success! Deleted directory: ' + dir_or_file)
		}
	} else if !whole_dir && os.is_file(dir_or_file) && rounds > 0 {
		new_fname := os.dir(os.real_path(dir_or_file)) + os.path_separator + rand.string(12)
		os.mv(dir_or_file, new_fname)!
		if !options.no_output {
			println('Shredding file... ' + os.file_name(dir_or_file))
		}
		shred_file(new_fname, rounds, options) or {
			println('Something went wrong...')
			println('\tError message: ' + err.msg())
			return
		}
		println('Success! Shredded file: ' + dir_or_file)
	} else {
		println('Flags incorrect!')
		if !whole_dir && os.is_dir(dir_or_file) {
			println('Hint: \'${dir_or_file}\' is a directory.')
		}
		if whole_dir && os.is_file(dir_or_file) {
			println('Hint: \'${dir_or_file}\' is a file not a directory (remove -d).')
		}
		if dir_or_file == '' {
			println('Hint: no file or directory specified.')
		}
		println("Maybe there is a typo, the file/dir does not exist or 'rounds' is lower 1\n")
		if os.input('Show usage? (y/n) ') == 'y' {
			println(fp.usage())
		}
	}
	println('Bye!')
}
