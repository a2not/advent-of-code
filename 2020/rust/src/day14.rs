#[cfg(test)]
mod tests {
    use crate::day14::*;

    #[test]
    fn parse_example() {
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

    #[test]
    fn part1_example() {
        let got = solve_part1_example();
        assert_eq!(got, 165);
    }

    #[test]
    fn part1() {
        let got = solve_part1();
        assert_eq!(got, 9967721333886);
    }
}

pub const INPUT: &str = include_str!("./day14_input.txt");
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

fn part1(input: &[Instruction]) -> u64 {
    let mut current_mask = None;

    use std::collections::HashMap;
    let mut memory = HashMap::new();

    input.iter().for_each(|instruction| match instruction {
        Instruction::Mask { ones, xs } => {
            current_mask = Some(Instruction::Mask {
                ones: *ones,
                xs: *xs,
            });
        }
        Instruction::Mem { address, value } => {
            if let Some(Instruction::Mask { ones, xs }) = current_mask {
                let new_value = value & xs | ones;
                memory.insert(address, new_value);
            } else {
                unreachable!();
            };
        }
    });

    memory.iter().fold(0, |acc, (_, v)| acc + *v)
}

#[allow(unused)]
fn solve_part1_example() -> u64 {
    let input = parse(INPUT_EXAMPLE_P1);
    part1(&input)
}

pub fn solve_part1() -> u64 {
    let input = parse(INPUT);
    part1(&input)
}
