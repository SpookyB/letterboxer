using ArgParse

### helper

function az_mask(char::Char)
    return UInt32(2^(char - 'a'))
end 

function az_trail(string::String)
    map(az_mask, collect(string))
end

function enumerate_from(iter, start, step=1)
    zip(Iterators.countfrom(start, step), iter)
end

### constructors

struct Puzzle
    positions::Dict{UInt32, UInt32}
    letters::UInt32
    function Puzzle(string::String, side_length::UInt32)
        trail = az_trail(string)
        positions = Dict(letter => index÷side_length
            for (index, letter) in enumerate_from(trail, side_length))
        return new(positions, reduce(|, trail))
    end
end

struct Word
    index::UInt32
    last::UInt32
    letters::UInt32
    function Word(trail::Array{UInt32}, index::UInt32)
        return new(index, trail[end], reduce(|, trail))
    end
end

struct Solution
    prev::Union{Solution,Nothing}
    index::UInt32
    last::UInt32
    letters::UInt32
    function Solution(solution::Solution, word::Word)
        letters = solution.letters | word.letters
        return new(solution, word.index, word.last, letters)
    end
    function Solution(word::Word)
        return new(nothing, word.index, word.last, word.letters)
    end
end

### logic

function walkable(puzzle, trail)
    last = 0
    for letter in trail
        current = get(puzzle.positions, letter, 0)
        if (current == last) | (current == 0)
            return false
        end
        last = current
    end
    return true
end

function print_solutions(puzzle, dictionary, maximum_solution_size)

    words = Dict()
    solutions = []
    for (index, entry) in enumerate(dictionary)
        trail = az_trail(entry)
        if walkable(puzzle, trail)
            word = Word(trail, UInt32(index))
            words[trail[1]] = [get(words, trail[1], []); word]
            solutions = [solutions; Solution(word)]
        end
    end

    for solution_size in range(1, maximum_solution_size)

        if solution_size != 1
            solutions = Iterators.flatten(
                [Solution(solution, word) for word in words[solution.last]]
                    for solution in solutions)
        end

        println("===$(solution_size) word solutions===")
        for solution in solutions
            if puzzle.letters == solution.letters
                text = ""
                while solution != nothing
                    text = "$(dictionary[solution.index]) $text"
                    solution = solution.prev
                end
                println(text)
            end
        end

    end

end

### io

function load_dictionary(dictionary_path, minimum_word_length)
    dictionary_file = open(dictionary_path, "r")
    dictionary = collect(eachline(dictionary_file))
    close(dictionary_file)
    if minimum_word_length > 1
        dictionary = filter((entry) -> length(entry) > minimum_word_length, dictionary)
    end
    return dictionary
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "letters"
            arg_type = String
            required = true
        "side_length"
            arg_type = UInt32
            default = UInt32(3)
        "-d", "--dictionary"
            help = "path to dictionary_path"
            arg_type = String
            dest_name = "dictionary_path"
            default = "./resources/dictionary.txt"
        "-m", "--minimum"
            help = "minimum word length"
            arg_type = UInt32
            dest_name = "minimum_word_length"
            default = UInt32(1)
        "-s", "--solutions"
            help = "max words for solutions"
            arg_type = UInt32
            dest_name = "maximum_solution_size"
            default = UInt32(3)
    end
    return parse_args(s)
end

function main(opt)
    puzzle = Puzzle(opt["letters"], opt["side_length"])
    dictionary = load_dictionary(opt["dictionary_path"], opt["minimum_word_length"])
    print_solutions(puzzle, dictionary, opt["maximum_solution_size"])
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(parse_commandline())
end
