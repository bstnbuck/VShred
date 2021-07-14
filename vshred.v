import rand
import os
import flag

const (
	// 1MB
	buffersize = 1048576
)

fn shred_dir(dir string, rounds int) bool {
	println('Shredding directory...')

	// get files to delete
	files := make_files_list(os.real_path(dir))
	println(files)

	mut enc_files := []string{}
	for file in files {
		new_fname := os.dir(file) + os.path_separator + rand.string(12)
		os.mv(file, new_fname) or {
			println('Error while renaming file: ' + os.file_name(file))
			println(err)
			return false
		}
		enc_files << new_fname
	}

	// remove file for file
	for i, file in enc_files {
		println('Next file: ' + os.file_name(files[i]))
		println('Shredding file... ' + files[i])
		shred_file(file, rounds) or {
			println('Error while shredding file: ' + os.file_name(files[i]))
			println(err)
			return false
		}
		println('Completed!\n')
	}
	os.rmdir_all(os.real_path(dir)) or {
		println('Error while removing directory: ' + err.msg)
		return false
	}
	println('Removed directory successfull')
	return true
}

fn make_files_list(dir string) []string {
	println('Entering dir: ' + dir)

	dir_content := os.ls(dir) or { [] }
	mut files := []string{}

	for content in dir_content {
		fpath := os.join_path(dir, content)
		if os.is_dir(fpath) {
			files << make_files_list(fpath)
		} else {
			files << fpath
		}
	}
	return files
}

fn shred_file(file_str string, rounds int) ?bool {
	file := os.real_path(file_str)
	file_len := os.file_size(file)

	if file_len > 0 {
		mut i := 1
		mut f := os.create(file) ? // binary write mode
		mut file_len_temp := u64(0)

		print('Shred rounds $rounds => Working round: ')
		for i <= rounds {
			print('$i ')
			for {
				// use buffersize for byte array length
				if (file_len_temp + buffersize) <= file_len && file_len > buffersize {
					if i != rounds {
						mut random_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. buffersize {
							random_bytes << rand.byte()
						}
						f.write_to(file_len_temp, random_bytes) ?
					} else {
						mut nulls_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. buffersize {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes) ?
					}
					file_len_temp += buffersize
				} else {
					if i != rounds {
						mut random_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. file_len - file_len_temp {
							random_bytes << rand.byte()
						}
						f.write_to(file_len_temp, random_bytes) ?
					} else {
						mut nulls_bytes := []byte{}

						// create new output as random byte array of buffer size
						for _ in 0 .. file_len - file_len_temp {
							nulls_bytes << `0`
						}
						f.write_to(file_len_temp, nulls_bytes) ?
					}
					file_len_temp = 0
					break
				}
			}
			i++
		}
		f.close()
		println('Done')
	}
	print('Removing File... ')

	// remove file
	os.rm(file) or {
		println('Could not remove file: ' + err.msg)
		return false
	}
	println('Done!')
	return true
}

fn main() {
	// set flags
	mut fp := flag.new_flag_parser(os.args)
	fp.application('VShred (Securely delete files)')
	fp.version('v1.2')
	fp.description('VShred securely delete files, you do not need anymore. Files will be written with random and zero bytes')
	whole_dir := fp.bool('dir', 0, false, 'secure delete whole directory')
	dir_name := fp.string('dir_name', 0, '', 'name of directory, which should be shred. No empty directories!')
	file_name := fp.string('file_name', 0, '', 'secure delete a file')
	rounds := fp.int('rounds', 0, 5, 'define how often the file should be overridden (> 0)')

	_ := fp.finalize() or {
		println(fp.usage())
		return
	}

	println('VShred -- secure delete files!')

	// check if flags correct set
	if whole_dir && os.is_dir(dir_name) && !os.is_dir_empty(dir_name) && rounds > 0 {
		if !shred_dir(dir_name, rounds) {
			println('Something went wrong...')
			return
		}
		println('Success! Deleted directory: ' + dir_name)
	} else if !whole_dir && os.is_file(file_name) && rounds > 0 {
		new_fname := os.dir(os.real_path(file_name)) + os.path_separator + rand.string(12)
		os.mv(file_name, new_fname) ?
		println('Shredding file... ' + os.file_name(file_name))
		shred_file(new_fname, rounds) or {
			println('Something went wrong...')
			println(err)
			return
		}
		println('Success! Shredded file: ' + file_name)
	} else {
		println('Flags incorrect!')
		println("Maybe there is a typo, the file/dir does not exist or 'rounds' is lower 1\n")
		if os.input('Show usage? (y/n) ') == 'y' {
			println(fp.usage())
		}
	}
	println('Bye!')
}
