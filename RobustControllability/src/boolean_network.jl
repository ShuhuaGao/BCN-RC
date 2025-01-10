# represent a BCN under disturbances
using JLD2
using DelimitedFiles
using Base.Iterators: product, repeated


struct BCN
    M::Int64
    N::Int64
    Q::Int64
    L::Vector{Int64}

    function BCN(M::Integer, N::Integer, Q::Integer, L::AbstractVector{<:Integer})
        @assert length(L) == M * N * Q
        @assert all(e -> 1 <= e <= N, L)
        return new(M, N, Q, convert(Vector{Int64}, L))
    end
end

# compute the next-step state of the BCN
function step(bcn::BCN, x::Integer, u::Integer, ξ::Integer)::Integer
    (; M, N) = bcn
    k = x
    j = u
    i = ξ
    blk_i = @view bcn.L[(i-1)*M*N+1:i*M*N]
    blk_j = @view blk_i[(j-1)*N+1:j*N]
    return blk_j[k]  # an integer
end

# compute the next-step state of the BCN
function step(bcn::BCN, x::LogicalVector, u::LogicalVector, ξ::LogicalVector)
    n = step(bcn, index(x), index(u), index(ξ))
    return LogicalVector(n, bcn.N)
end


"""
    calculate_ASSR(fs, m, q; to_file::String="") -> BCN

Given a list of Boolean functions `fs`, number of controls `m`, and number of disturbances `q`, 
build the algebraic form of the BCN.
If `to_file` is specified, then the BCN model is written into that file using `JLD2`.
The format depends on the `to_file` extensions: JLD2 (binary format), 
    or txt or dat (text format, each line for a number in `L`).
"""
function calculate_ASSR(fs::AbstractVector{<:Function}, m, q; to_file::String="")::BCN
    n = length(fs)
    Q = 2^q
    M = 2^m
    N = 2^n
    idx = Vector{Int64}(undef, Q * M * N) # index vector in L
    for xb in product(repeated([true, false], n)...)
        for ub in product(repeated([true, false], m)...)
            for ξb in product(repeated([true, false], q)...)
                # turn each boolean tuple into a logical vector, and multiply the RHS
                x = LogicalVector(collect(xb))
                u = LogicalVector(collect(ub))
                ξ = LogicalVector(collect(ξb))
                s = ξ * u * x
                # calculate the LHS with raw Boolean operators
                xb′ = BitVector()
                for fi in fs
                    push!(xb′, fi(xb, ub, ξb))
                end
                x′ = LogicalVector(xb′)
                # set the logical matrix
                idx[index(s)] = index(x′)
            end
        end
    end

    bcn = BCN(M, N, Q, idx)
    if !isempty(to_file)
        if endswith(to_file, "jld2")
            jldsave(to_file; bcn)
        elseif endswith(to_file, r"txt|dat")
            writedlm(to_file, [[bcn.M, bcn.N, bcn.Q]; bcn.L])
        else
            error("Unrecognized file format in `to_file`!")
        end
    end
    return bcn
end

function load_bcn(L_file::String)::BCN
    if endswith(L_file, r"txt|dat")
        data = readdlm(L_file, Int64)
        bcn = BCN(data[1:3]..., @view data[4:end])
        return bcn
    else
        error("Unrecognized file format in `L_file`!")
    end
end