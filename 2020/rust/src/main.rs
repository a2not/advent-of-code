const INPUT_STR: &str = include_str!("./day14_input.txt");

#[derive(Debug)]
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

const INPUT_EXAMPLE_P1: &str = "mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X
mem[8] = 11
mem[7] = 101
mem[8] = 0";

#[cfg(test)]
mod tests {
    #[test]
    fn day14_parse() {
        use super::*;
        parse(INPUT_EXAMPLE_P1);
        assert_eq!(2 + 2, 4);
    }
}

fn main() {
    let res = parse(INPUT_EXAMPLE_P1);
    println!("Day 14: {:?}", res);
    let res = parse(INPUT_STR);
    println!("Day 14: {:?}", res);
}
