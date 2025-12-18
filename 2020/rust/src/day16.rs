#[cfg(test)]
mod tests {
    use crate::day16::*;

    #[test]
    fn parse_example() {
        let got = parse(INPUT_EXAMPLE_PART_1);
        assert_eq!(
            got.ranges,
            vec![(1, 3), (5, 7), (6, 11), (33, 44), (13, 40), (45, 50)]
        );
    }

    #[test]
    fn part1_example() {
        let got = solve_part1_example();
        assert_eq!(got, 71);
    }

    #[test]
    fn part1() {
        let got = solve_part1();
        assert_eq!(got, 25984);
    }
}

const INPUT: &str = include_str!("./day16_input.txt");
const INPUT_EXAMPLE_PART_1: &str = "class: 1-3 or 5-7
row: 6-11 or 33-44
seat: 13-40 or 45-50

your ticket:
7,1,14

nearby tickets:
7,3,47
40,4,50
55,2,20
38,6,12";

struct Context {
    ranges: Vec<(u64, u64)>,
    nearby_tickets: Vec<u64>,
}

fn parse(input: &str) -> Context {
    let parts = input.splitn(3, "\n\n").collect::<Vec<_>>();

    let mut ranges: Vec<(u64, u64)> = Vec::new();

    parts.get(0).unwrap().lines().for_each(|line| {
        line.split(": ")
            .collect::<Vec<_>>()
            .get(1)
            .unwrap()
            .split(" or ")
            .for_each(|range| {
                let bounds: Vec<u64> = range
                    .split('-')
                    .map(|num| num.parse::<u64>().unwrap())
                    .collect();
                ranges.push((bounds[0], bounds[1]));
            });
    });

    let mut nearby_tickets: Vec<u64> = Vec::new();

    parts.get(2).unwrap().lines().skip(1).for_each(|line| {
        line.split(',')
            .map(|num| num.parse::<u64>().unwrap())
            .for_each(|num| nearby_tickets.push(num));
    });

    Context {
        ranges,
        nearby_tickets,
    }
}

fn part1(ctx: Context) -> u64 {
    ctx.nearby_tickets
        .iter()
        .map(|v| {
            let out_of_range = ctx.ranges.iter().all(|(low, high)| v < low || v > high);
            if out_of_range { *v } else { 0 }
        })
        .sum()
}

fn solve_part1_example() -> u64 {
    let ctx = parse(INPUT_EXAMPLE_PART_1);
    part1(ctx)
}

pub fn solve_part1() -> u64 {
    let ctx = parse(INPUT);
    part1(ctx)
}
