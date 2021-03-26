import rand
import os
import flag

fn shred_dir(dir string, rounds int) bool {
	println('Shredding directory...')

	// get files to delete
	files := make_files_list(os.real_path(dir))
	println(files)

	// remove file for file
	for file in files {
		println('Next file: ' + os.file_name(file))
		fsize := os.file_size(file)
		if fsize <= 900000000 {
			shred_file(file, rounds) or {
				println('Error while shredding file: ' + os.file_name(file))
				return false
			}
		} else {
			shred_big_file(file, rounds) or {
				println('Error while shredding file: ' + os.file_name(file))
				return false
			}
		}

		println('Completed!\n')
	}

	// remove all dirs recursively
	os.rmdir_all(os.real_path(dir)) or { println('Error while removing directory: ' + err.msg) }
	println('Removed directory successfull')
	return true
}

fn make_files_list(dir string) []string {
	println('Entering dir: ' + dir)

	// show current list of dir
	dir_content := os.ls(dir) or { return [] }
	mut files := []string{}

	// file for file
	for content in dir_content {
		// make correct path and check if is a dir
		if os.is_dir(os.join_path(dir, content)) {
			// recursively add more files of sub-dirs
			files << make_files_list(os.join_path(dir, content))
		} else {
			// else file to files
			files << os.join_path(dir, content)
		}
	}
	return files
}

// to handle bigger than 1 GB -> create array with file size - max allowed... -> use write_to() to give position
fn shred_file(file_str string, rounds int) ?bool {
	println('Shredding file... ' + file_str)

	// check correct path
	file := os.real_path(file_str)

	// get file size
	file_len := os.file_size(file) 

	if file_len > 0 {
		mut i := 1
		for i <= rounds {
			// overwrite the file i rounds
			// write byte instead string -> correct filesize
			if i != rounds {
				mut random_str := []byte{}
				for _ in 0 .. file_len {
					random_str << rand.byte()
				}
				mut f := os.create(file) ?
				f.write(random_str) ?
				f.close()
			} else {
				// create new output as zero byte array of file length
				mut nulls_str := []byte{}
				for _ in 0 .. file_len {
					nulls_str << `0`
				}
				mut f := os.create(file) ?
				f.write(nulls_str) ?
				f.close()
			}
			if i == 1 {
				print('Shred round 1')
			} else {
				print(' ' + i.str())
			}
			i++
		}
	}
	print('\nRemoving file... ')

	// remove the file
	os.rm(file) or {
		println('Could not remove file')
		return false
	}
	println('Done!')
	return true
}

fn shred_big_file(file_str string, rounds int) ?bool {
	println('Shredding big file... ' + file_str)

	// check correct path
	file := os.real_path(file_str)

	// get file size
	mut lens := []u64{}
	file_len := os.file_size(file) 
	mut file_len_temp := u64(0)

	if file_len > 0 {
		for {
			if file_len_temp < file_len {
				lens << file_len_temp
			} else {
				lens << file_len
				break
			}
			file_len_temp += 900000000
		}
	}
	println('lens: ' + lens.str())

	mut write_cond := 0
	for write_cond < lens.len - 1 {
		if write_cond != 0 {
			println('\nNext Part...')
		}

		mut i := 1
		for i <= rounds {
			// overwrite the file i rounds

			// write byte instead string -> correct filesize
			if i != rounds {
				mut random_str := []byte{}
				for _ in 0 .. lens[write_cond + 1] - lens[write_cond] {
					random_str << rand.byte()
				}
				mut f := os.create(file) ?
				f.write_to(lens[write_cond], random_str) ?
				f.close()
			} else {
				mut nulls_str := []byte{}

				// create new output as zero byte array of file length
				for _ in 0 .. lens[write_cond + 1] - lens[write_cond] {
					nulls_str << `0`
				}
				mut f := os.create(file) ?
				f.write_to(lens[write_cond], nulls_str) ?
				f.close()
			}
			if i == 1 {
				print('Shred round 1')
			} else {
				print(' ' + i.str())
			}
			i++
		}
		write_cond++
	}

	print('\nRemoving big file... ')

	// remove the file
	os.rm(file) or {
		println('Could not remove file')
		return false
	}
	println('Done!')
	return true
}

fn main() {
	// set flags
	mut fp := flag.new_flag_parser(os.args)
	fp.application('VShred (Securely delete files)')
	fp.version('v1.1')
	fp.description('VShred securely delete files, you do not need anymore. Files will be written with random and zero bytes')
	whole_dir := fp.bool('dir', 0, false, 'secure delete whole directory')
	dir_name := fp.string('dir_name', 0, '', 'name of dir, which should be shred. No empty directories!')
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
		fsize := os.file_size(file_name) 
		if fsize <= 900000000 {
			shred_file(file_name, rounds) or {
				println('Something went wrong...')
				return
			}
		} else {
			shred_big_file(file_name, rounds) or {
				println('Something went wrong...')
				return
			}
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
