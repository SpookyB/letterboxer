using ArgParse

include("letterboxer.jl")

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
        "-w", "--wordlength"
        help = "minimum word length"
        arg_type = UInt32
        dest_name = "word_length"
        default = UInt32(1)
        "-s", "--depth"
        help = "solution depth"
        arg_type = UInt32
        dest_name = "depth"
        default = UInt32(3)
        "-o", "--out"
        help = "path to output file (disables stdout)"
        arg_type = String
        dest_name = "output_path"
    end
    return parse_args(s)
end

function command(opt)

    dictionary_file = open(opt["dictionary_path"], "r")
    dictionary = collect(eachline(dictionary_file))
    close(dictionary_file)
    if opt["word_length"] > 1
        dictionary = dictionary[length.(dictionary).>=opt["word_length"]]
    end
    if isnothing(opt["output_path"])
        main(dictionary, opt["letters"]; side_length=opt["side_length"],
            depth=opt["depth"])
    else
        io = open(opt["output_path"], "w")
        main(dictionary, opt["letters"]; side_length=opt["side_length"],
            depth=opt["depth"], io=io)
        close(io)
    end

end

if abspath(PROGRAM_FILE) == @__FILE__
    command(parse_commandline())
end
