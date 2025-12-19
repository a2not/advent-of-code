#[cfg(test)]
mod tests {
    use crate::day16::*;

    #[test]
    fn parse_example() {
        let got = parse(INPUT_EXAMPLE_PART_1);
        assert_eq!(
            got,
            Context {
                fields: vec![
                    Field {
                        name: "class".to_string(),
                        ranges: vec![(1, 3), (5, 7)],
                    },
                    Field {
                        name: "row".to_string(),
                        ranges: vec![(6, 11), (33, 44)],
                    },
                    Field {
                        name: "seat".to_string(),
                        ranges: vec![(13, 40), (45, 50)],
                    },
                ],
                my_ticket: vec![7, 1, 14],
                nearby_tickets: vec![
                    vec![7, 3, 47],
                    vec![40, 4, 50],
                    vec![55, 2, 20],
                    vec![38, 6, 12],
                ],
                all_tickets: vec![
                    vec![7, 3, 47],
                    vec![40, 4, 50],
                    vec![55, 2, 20],
                    vec![38, 6, 12],
                    vec![7, 1, 14],
                ],
            }
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

    // #[test]
    // fn part2_example() {
    //     let got = solve_part2_example();
    //     assert_eq!(got, 1);
    // }
    //
    #[test]
    fn part2() {
        let got = solve_part2();
        assert_eq!(got, 0);
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
const INPUT_EXAMPLE_PART_2: &str = "class: 0-1 or 4-19
row: 0-5 or 8-19
seat: 0-13 or 16-19

your ticket:
11,12,13

nearby tickets:
3,9,18
15,1,5
5,14,9";

#[derive(Debug, PartialEq)]
struct Field {
    name: String,
    ranges: Vec<(u64, u64)>,
}

#[derive(Debug, PartialEq)]
struct Context {
    fields: Vec<Field>,
    my_ticket: Vec<u64>,
    nearby_tickets: Vec<Vec<u64>>,

    all_tickets: Vec<Vec<u64>>,
}

fn parse(input: &str) -> Context {
    let parts = input.splitn(3, "\n\n").collect::<Vec<_>>();

    let mut fields: Vec<Field> = Vec::new();

    parts.get(0).unwrap().lines().for_each(|line| {
        let parts = line.split(": ").collect::<Vec<_>>();

        let field_name = parts.get(0).unwrap().to_string();

        let ranges = parts
            .get(1)
            .unwrap()
            .split(" or ")
            .map(|range| {
                let bounds: Vec<u64> = range
                    .split('-')
                    .map(|num| num.parse::<u64>().unwrap())
                    .collect();
                (bounds[0], bounds[1])
            })
            .collect::<Vec<(u64, u64)>>();

        fields.push(Field {
            name: field_name,
            ranges,
        });
    });

    let my_ticket = parts
        .get(1)
        .unwrap()
        .lines()
        .nth(1)
        .unwrap()
        .split(",")
        .map(|num| num.parse::<u64>().unwrap())
        .collect::<Vec<u64>>();

    let nearby_tickets = parts
        .get(2)
        .unwrap()
        .lines()
        .skip(1)
        .map(|line| {
            line.split(',')
                .map(|num| num.parse::<u64>().unwrap())
                .collect::<Vec<u64>>()
        })
        .collect::<Vec<Vec<u64>>>();

    let mut all_tickets = nearby_tickets.clone();
    all_tickets.push(my_ticket.clone());

    Context {
        fields,
        my_ticket,
        nearby_tickets,
        all_tickets,
    }
}

fn part1(ctx: Context) -> u64 {
    let Context {
        fields,
        my_ticket: _,
        nearby_tickets,
        all_tickets: _,
    } = ctx;

    nearby_tickets
        .iter()
        .flat_map(|ticket| ticket.iter())
        .map(|v| {
            let out_of_range = fields
                .iter()
                .all(|field| field.ranges.iter().all(|(low, high)| v < low || v > high));
            if out_of_range { *v } else { 0 }
        })
        .sum()
}

fn part2(ctx: Context) -> u64 {
    let Context {
        fields,
        my_ticket,
        nearby_tickets: _,
        all_tickets,
    } = ctx;

    // TODO: ignore some tickets that are invalid

    let mut result = 1;

    use std::collections::{BinaryHeap, HashMap, HashSet};
    let mut candidates = HashMap::<usize, HashSet<usize>>::new();

    let m = all_tickets.get(0).unwrap().len();

    for j in 0..m {
        for (field_index, field) in fields.iter().enumerate() {
            let possible = all_tickets.iter().all(|ticket| {
                let v = ticket.get(j).unwrap();
                field
                    .ranges
                    .iter()
                    .any(|(low, high)| *low <= *v && *v <= *high)
            });
            if possible {
                println!("field {:?} can be column {:?}", field.name, j);
                candidates.entry(field_index).or_default().insert(j);
            }
        }
    }

    let mut pq = candidates
        .iter()
        .map(|(field_index, positions)| (-(positions.len() as isize), *field_index))
        .collect::<BinaryHeap<(isize, usize)>>();

    println!("candidates: {:?}", candidates);
    println!("pq: {:?}", pq);

    let mut fixed_column = HashSet::<usize>::new();

    while let Some((_, field_index)) = pq.pop() {
        let fixed_column_clone = fixed_column.clone();
        let cands = candidates
            .get(&field_index)
            .unwrap()
            .difference(&fixed_column_clone)
            .collect::<Vec<&usize>>();

        if cands.len() != 1 {
            unreachable!();
        }

        let col = cands.get(0).unwrap();
        fixed_column.insert(**col);

        let field = fields.get(field_index).unwrap();
        println!("field {:?} is column {:?}", field.name, col);
        if field.name.starts_with("departure") {
            result *= my_ticket.get(**col).unwrap();
        }
    }

    return result;
}

fn solve_part1_example() -> u64 {
    let ctx = parse(INPUT_EXAMPLE_PART_1);
    part1(ctx)
}

fn solve_part1() -> u64 {
    let ctx = parse(INPUT);
    part1(ctx)
}

fn solve_part2_example() -> u64 {
    let ctx = parse(INPUT_EXAMPLE_PART_2);
    part2(ctx)
}

fn solve_part2() -> u64 {
    let ctx = parse(INPUT);
    part2(ctx)
}
