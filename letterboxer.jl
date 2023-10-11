using ArgParse

### helper

function az_num(char::Char)
    return UInt8(char - 'a')
end 

function az_trail(string::String)
    return map(az_num, collect(string))
end

function trail_letters(trail)
    return reduce(|, map(UInt32, map(exp2, trail)))
end

function enumerate_from(iter, start, step=1)
    return zip(Iterators.countfrom(start, step), iter)
end

### types

struct Proposal
    next::Union{ Base.RefValue{Proposal}, Base.RefValue{Nothing} }
    first::UInt8
    index::UInt16
    letters::UInt32
    function Proposal(trail, index)
        return Ref(new(Ref(nothing), trail[1], index, trail_letters(trail)))
    end
    function Proposal(this::Base.RefValue{Proposal}, next::Base.RefValue{Proposal})
        return Ref(new(next, this[].first, this[].index, this[].letters | next[].letters))
    end
end

### logic

function puzzle(string::String, side_length::UInt32)
    trail = az_trail(string)
    positions = Dict(letter => index÷side_length
        for (index, letter) in enumerate_from(trail, side_length))
    return positions, trail_letters(trail)
end

function walkable(positions, trail)
    last = -1
    for letter in trail
        current = get(positions, letter, -1)
        if (current == last) | (current == -1)
            return false
        end
        last = current
    end
    return true
end

function build_words(positions, dictionary)
    words = Dict(letter => [] for letter in az_trail("abcdefghijklmnopqrstuvwxyz"))
    trimmed_dictionary = []
    for entry in dictionary
        trail = az_trail(entry)
        if walkable(positions, trail)
            push!(trimmed_dictionary, entry)
            push!(words[trail[end]], Proposal(trail, length(trimmed_dictionary)))
        end
    end
    return words, trimmed_dictionary
end

function print_proposal(io, words, dictionary, proposal)
    text = []
    while proposal[] != nothing
        push!(text, dictionary[proposal[].index])
        proposal = proposal[].next
    end
    println(io, join(text, " "))
end

function print_solutions(io, required, words, dictionary, proposal, depth) 

    if required == proposal[].letters
        print_proposal(io, words, dictionary, proposal)
    end

    if depth > 1
        for word in words[proposal[].first]
            print_solutions(io, required, words, dictionary, Proposal(word, proposal), depth-1)
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
            help = "path to dictionary"
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
        "-o", "--out"
            help = "path to output file (disables stdout)"
            arg_type = String
            dest_name = "output_path"
    end
    return parse_args(s)
end

function main(opt)
    positions, required = puzzle(opt["letters"], opt["side_length"])
    dictionary = load_dictionary(opt["dictionary_path"], opt["minimum_word_length"])
    words, dictionary = build_words(positions, dictionary)
    io = isnothing(opt["output_path"]) ? stdout : open(opt["output_path"], "w")
    for letter in values(words)
        Threads.@threads for proposal in letter
            print_solutions(io, required, words, dictionary, proposal, opt["maximum_solution_size"])
        end
    end
    close(io)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(parse_commandline())
end
