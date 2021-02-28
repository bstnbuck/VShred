module os_stat


pub struct File {
	cfile voidptr // Using void* instead of FILE*
pub:
	fd int
pub mut:
	is_opened bool
}

fn C.fseeko64(voidptr, u64, int) int

fn C._fseeki64(voidptr, u64, int) int

// create creates or opens a file at a specified location and returns a write-only `File` object.
pub fn create(path string) ?File {
	cfile := vfopen(path, 'wb') ?
	fd := fileno(cfile)
	return File{
		cfile: cfile
		fd: fd
		is_opened: true
	}
}

pub fn (mut f File) f_write_to(pos u64, buf []byte) ?int {
	$if windows{
		C._fseeki64(f.cfile, pos, C.SEEK_SET)
		res := int(C.fwrite(buf.data, 1, buf.len, f.cfile))
		C._fseeki64(f.cfile, 0, C.SEEK_END)

		return res
	}$else{
		C.fseeko64(f.cfile, pos, C.SEEK_SET)
		res := int(C.fwrite(buf.data, 1, buf.len, f.cfile))
		C.fseeko64(f.cfile, 0, C.SEEK_END)
			
		return res
	}

}

pub fn (mut f File) close() {
	if !f.is_opened {
		return
	}
	f.is_opened = false
	C.fflush(f.cfile)
	C.fclose(f.cfile)
}