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

### types

struct Word
    text::String
    last::UInt32
    letters::UInt32
end

struct Proposal
    prev::Union{Proposal,Nothing}
    word::Word
    letters::UInt32
    function Proposal(word::Word)
        return new(nothing, word, word.letters)
    end
    function Proposal(proposal::Proposal, word::Word)
        return new(proposal, word, proposal.letters | word.letters)
    end
end

### logic

function puzzle(string::String, side_length::UInt32)
    trail = az_trail(string)
    positions = Dict(letter => index÷side_length
        for (index, letter) in enumerate_from(trail, side_length))
    return positions, reduce(|, trail)
end

function walkable(positions, trail)
    last = 0
    for letter in trail
        current = get(positions, letter, 0)
        if (current == last) | (current == 0)
            return false
        end
        last = current
    end
    return true
end

function build_words(positions, dictionary)
    words = Dict()
    for entry in dictionary
        trail = az_trail(entry)
        if walkable(positions, trail)
            word = Word(entry, trail[end], reduce(|, trail))
            words[trail[1]] = [get(words, trail[1], []); word]
        end
    end
    return words
end

function print_proposal(io, proposal)
    text = ""
    while proposal != nothing
        text = "$(proposal.word.text) $text"
        proposal = proposal.prev
    end
    println(io, text)
end

function print_solutions(io, required, words, proposal, depth) 

    if required == proposal.letters
        print_proposal(io, proposal)
    end

    if depth > 1
        for word in words[proposal.word.last]
            print_solutions(io, required, words, Proposal(proposal, word), depth-1)
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
    words = build_words(positions, dictionary)
    io = isnothing(opt["output_path"]) ? stdout : open(opt["output_path"], "w")
    for letter in values(words)
        Threads.@threads for word in letter
            print_solutions(io, required, words, Proposal(word), opt["maximum_solution_size"])
        end
    end
    close(io)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(parse_commandline())
end
