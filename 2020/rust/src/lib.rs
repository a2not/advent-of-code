#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn day14_parse() {
        let got = parse(INPUT_EXAMPLE_P1);
        assert_eq!(
            got,
            vec![
                Instruction::Mask {
                    ones: 0b1000000,
                    xs: 0b111111111111111111111111111110111101,
                },
                Instruction::Mem {
                    address: 8,
                    value: 11,
                },
                Instruction::Mem {
                    address: 7,
                    value: 101,
                },
                Instruction::Mem {
                    address: 8,
                    value: 0,
                },
            ],
        );
    }
}

pub const INPUT_STR: &str = include_str!("./day14_input.txt");
pub const INPUT_EXAMPLE_P1: &str = "mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X
mem[8] = 11
mem[7] = 101
mem[8] = 0";

#[derive(PartialEq, Debug)]
pub enum Instruction {
    Mask { ones: u64, xs: u64 },
    Mem { address: u64, value: u64 },
}

impl Instruction {
    fn mask(pattern: &str) -> Instruction {
        let mut ones = 0;
        let mut xs = 0;

        for b in pattern.bytes() {
            ones <<= 1;
            xs <<= 1;
            match b {
                b'1' => ones |= 1,
                b'X' => xs |= 1,
                _ => (),
            }
        }

        Self::Mask { ones, xs }
    }
}

pub fn parse(input: &str) -> Vec<Instruction> {
    input
        .lines()
        .map(|line| {
            let (before, after) = line.split_once(" = ").unwrap();
            match before {
                "mask" => Instruction::mask(after),
                _ => Instruction::Mem {
                    address: before["mem[".len()..(before.len() - "]".len())]
                        .parse::<u64>()
                        .unwrap(),
                    value: after.parse::<u64>().unwrap(),
                },
            }
        })
        .collect()
}
