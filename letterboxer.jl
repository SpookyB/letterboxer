using ArgParse

### helper

function az_mask(character)
    return UInt32(2^(character - 'a'))
end 

### constructors

struct Component
    word::String
    trail::Array{UInt32}
    contents::UInt32
    function Component(word::String)
        trail = map(az_mask, collect(word))
        contents = reduce(|, trail)
        return new(word, trail, contents)
    end
end

struct Solution
    words::Array{String}
    contents::UInt32
    function Solution(s::Solution, c::Component)
        if s.words[end][end] != c.word[1]
            return nothing
        end
        words = [s.words; c.word]
        contents = s.contents | c.contents
        return new(words, contents)
    end
    function Solution(s::Nothing, c::Component)
        return new([c.word], c.contents)
    end
end

struct Puzzle
    sides::Array{UInt32}
    contents::UInt32
    function Puzzle(letters, side_length)
        az_indices = map(az_mask, collect(letters))
        sides = [reduce(|, side_indices) for side_indices in Iterators.partition(az_indices, side_length)]
        contents = reduce(|, sides)
        return new(sides, contents)
    end
end

### logic

function walkable(puzzle, component)
    if puzzle.contents != (puzzle.contents | component.contents)
        return false
    end
    last = 0
    for node in component.trail
        current = findfirst((side == (side | node) for side in puzzle.sides))
        if (current == nothing) | (current == last)
            return false
        end
        last = current
    end
    return true
end

function print_valid(puzzle, words, maximum_solution_size)
    _walkable(component) = walkable(puzzle, component)
    components = filter(_walkable, map(Component, words))
    solutions = [nothing]
    for solution_size in 1:maximum_solution_size
        pairs = Iterators.product(solutions, components)
        solutions = filter(!isnothing, map((pair) -> Solution(pair[1], pair[2]), pairs))
        println("===$(solution_size) word solutions===")
        for solution in solutions
            if puzzle.contents == solution.contents
                println(join(solution.words, " "))
            end
        end
    end
end

### io

function load_dictionary(dictionary, minimum_word_length)
    words_txt = open(dictionary, "r")
    words = collect(eachline(words_txt))
    close(words_txt)
    if minimum_word_length > 1
        words = filter((word) -> length(word) > minimum_word_length, words)
    end
    return words
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "letters"
            arg_type = String
            required = true
        "side_length"
            arg_type = Int
            default = 3
        "-d", "--dictionary"
            help = "path to dictionary"
            arg_type = String
            dest_name = "dictionary"
            default = "./resources/dictionary.txt"
        "-m", "--minimum"
            help = "minimum word length"
            arg_type = Int
            dest_name = "minimum_word_length"
            default = 1
        "-s", "--solutions"
            help = "max words for solutions"
            arg_type = Int
            dest_name = "maximum_solution_size"
            default = 3
    end
    return parse_args(s)
end

function main()
    opt = parse_commandline()
    words = load_dictionary(opt["dictionary"], opt["minimum_word_length"])
    puzzle = Puzzle(opt["letters"], opt["side_length"])
    print_valid(puzzle, words, opt["maximum_solution_size"])
end

main()

