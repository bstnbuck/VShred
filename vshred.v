import rand
import os
import flag

fn shred_dir(dir string, rounds int) ? {
	println('Shredding directory...')
	// get files to delete
	files := make_files_list(os.real_path(dir))
	println(files)
	// remove file for file
	for file in files {
		println('Next file: ' + os.file_name(file))
		shred_file(file, rounds) ?
		println('Completed!\n')
	}
	// remove all dirs recursively
	os.rmdir_all(dir) ?
	println('Removed directory successfull')
}

fn make_files_list(dir string) []string {
	println(dir)
	// show current list of dir
	dir_content := os.ls(dir) or { return [] }
	mut files := []string{}
	// file for file
	for content in dir_content {
		// make correct path and check if is a dir
		if is_dir(os.join_path(dir, content)) {
			// recursively add more files of sub-dirs
			files << make_files_list(os.join_path(dir, content))
		} else {
			// else file to files
			files << os.join_path(dir, content)
		}
	}
	return files
}

fn shred_file(file_str string, rounds int) ? {
	println('Shredding file...' + file_str)
	// check correct path
	file := os.real_path(file_str)
	// get file size
	file_len := os.file_size(file)
	mut nulls_str := []byte{}
	if file_len > 0 {
		// create new output as zero byte array of file length
		for _ in 0 .. file_len {
			nulls_str << `0`
		}
		mut i := 1
		for i <= rounds {
			// overwrite the file i rounds
			random_str := rand.string(file_len)
			if i != rounds {
				os.write_file(file, random_str) ?
			} else {
				os.write_file(file, nulls_str.str()) ?
			}
			if i == 1 {
				print('Shred round 1')
			} else {
				print(' ' + i.str())
			}
			i++
		}
	}
	println('\nRemoving file...')
	// remove the file
	os.rm(file) ?
	println('Removed file!')
}

fn main() {
	// set flags
	mut fp := flag.new_flag_parser(os.args)
	fp.application('V-Shred (Securely delete files)')
	fp.version('v0.0.1alpha')
	fp.description('V-Shred securely delete files, you do not need anymore. Files will be written with random and zero bytes')
	whole_dir := fp.bool('dir', 0, false, 'secure delete whole directory')
	dir_name := fp.string('dir_name', 0, '', 'name of dir, which should be shred. No empty directories!')
	file_name := fp.string('file_name', 0, '', 'secure delete a file')
	rounds := fp.int('rounds', 0, 3, 'define how often the file should be overridden')

	_ := fp.finalize() or {
		println(fp.usage())
		return
	}

	// check if flags correct set
	if whole_dir && os.is_dir(dir_name) && !os.is_dir_empty(dir_name) {
		shred_dir(dir_name, rounds) or {
			println('Something went wrong...')
			return
		}
		println('Success! Deleted directory: ' + dir_name)
	} else if !whole_dir && os.is_file(file_name) {
		shred_file(file_name, rounds) or {
			println('Something went wrong...')
			return
		}
		println('Success! Shredded file: ' + file_name)
	} else {
		println(fp.usage())
	}
	println('Closing...')
}
