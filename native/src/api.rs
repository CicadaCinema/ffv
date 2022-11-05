use std::fs::File;
use std::io::{BufRead, BufReader};
use std::thread;
use highway::{HighwayHasher, HighwayHash};

fn hash(path: String) -> [u64; 4] {
    let mut hasher = HighwayHasher::default();
    let f = File::open(path).unwrap();
    let mut reader = BufReader::new(f);

    // read the file using a buffer and add the buffer to the hasher each iteration
    // to avoid reading the entire file into memory
    loop {
        let buffer = reader.fill_buf().unwrap();
        if buffer.is_empty() {
            break;
        }
        hasher.append(buffer);
        let length = buffer.len();
        reader.consume(length);
    }

    // return the resulting hash
    hasher.finalize256()
}

pub fn compare(left: String, right: String) -> bool {
    // perform each hash calculation in a different thread
    let left_computation = thread::spawn(|| {
        hash(left)
    });
    let right_computation = thread::spawn(|| {
        hash(right)
    });

    // compare the hashes once the computations terminate
    left_computation.join().unwrap() == right_computation.join().unwrap()
}
