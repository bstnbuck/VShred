module os_stat

#include <sys/stat.h>

fn C.lstat64(charptr, voidptr) u64

fn C._wstat64(charptr, voidptr)

struct C.stat {
	st_size  u64
	st_mode  u32
	st_mtime int
}

struct C.__stat64 {
	st_size  u64
	st_mode  u32
	st_mtime int
}

pub fn f_size(path string) ?u64 {
	mut s := C.stat{}

	unsafe {
		$if windows {
			// the win tcc now supports 64 bit OSes
			mut swin := C.__stat64{}
			C._wstat64(path.to_wide(), voidptr(&swin))
			return swin.st_size
		} $else {
			// lstat64 returns integer with 64 bit on 64 bit OSes, 32 bit ints on 32 bit OSes
			C.lstat64(charptr(path.str), &s)
			return u64(s.st_size)
		}
	}
	return error('Bad OS')
}
