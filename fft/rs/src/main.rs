use fft::{fft, Complex};
use std::f64::consts::PI;

#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

fn round(n: f64) -> f64 {
    // precision = 2
    (n * 100.0).round() / 100.0
}

fn generate_inputs(len: usize) -> Vec<Complex> {
    // Use iterator to generate inputs more efficiently
    (0..len)
        .map(|i| {
            let theta = i as f64 / len as f64 * PI;
            let re = 1.0 * (10.0 * theta).cos() + 0.5 * (25.0 * theta).cos();
            let im = 1.0 * (10.0 * theta).sin() + 0.5 * (25.0 * theta).sin();
            Complex::new(round(re), round(im))
        })
        .collect()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let size = args[1].parse::<usize>().unwrap();
    let mut signals = generate_inputs(1 << size);
    let start = std::time::Instant::now();
    fft(&mut signals);
    let end = std::time::Instant::now();

    if args.len() > 2 {
        // Use iterator chain for file parsing and verification
        let expected_values: Vec<Complex> = std::fs::read_to_string(&args[2])
            .unwrap()
            .lines()
            .map(|line| {
                let (re_str, im_str) = line.split_once(',').unwrap();
                Complex::new(re_str.parse().unwrap(), im_str.parse().unwrap())
            })
            .collect();

        // Use iterator for verification
        signals
            .iter()
            .zip(expected_values.iter())
            .for_each(|(actual, expected)| {
                assert_eq!(actual, expected);
            });
    } else {
        println!(
            "execution time: {:.3} ms",
            end.duration_since(start).as_secs_f64() * 1000.0
        );
    }
}
