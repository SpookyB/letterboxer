struct Predicate
    first::UInt8
    index::UInt16
    letters::UInt32
end

struct SolutionsPrinter
    io::IO
    letters::UInt32
    words::Vector{String}
    predicates::Dict{UInt8,Array{Predicate}}
    depth::UInt8
end

function (sp::SolutionsPrinter)(
        predicate, depth, letters=UInt32(0), indices=zeros(UInt16, sp.depth))
  
    letters |= predicate.letters
    indices[depth] = predicate.index
    depth -= UInt8(1)

    if letters == sp.letters
        print(sp.io, join(sp.words[indices[indices.!=0]], " ") * "\n")
    end

    if depth > 0
        for predicate in sp.predicates[predicate.first]
            sp(predicate, depth, letters, indices)
        end
    end

end
    
function az_trail(string::String)
    return (char -> UInt8(char - 'a')).(collect(string))
end

function trail_letters(trail::Array{UInt8})
    return reduce(|, UInt32.(exp2.(trail)))
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

function main(dictionary, letters; side_length=3, depth=3, io=stdout)

    @assert depth > 0
    @assert side_length > 0
    @assert iszero(length(letters) % side_length)
    
    trail = az_trail(letters)
    required_letters = trail_letters(trail)
    positions = Dict{UInt8,UInt8}()
    for side in 1:length(trail)÷side_length
        for _ in 1:side_length
            positions[pop!(trail)] = side
        end
    end

    predicates = Dict(letter => [] for letter in UInt8.(0:25))
    words = String[]
    for word in dictionary
        trail = az_trail(word)
        if walkable(positions, trail)
            push!(words, word)
            p = Predicate(trail[1], length(words), trail_letters(trail))
            push!(predicates[trail[end]], p)
        end
    end

    sp = SolutionsPrinter(io, required_letters, words, predicates, depth)
    for letter in values(predicates)
        Threads.@threads for predicate in letter
            sp(predicate, UInt8(depth))
        end
    end

end
