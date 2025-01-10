# STP related operations

# δₙⁱ
struct LogicalVector
    i::Int64
    n::Int64

    function LogicalVector(i::Integer, n::Integer)
        @assert 1 <= i <= n
        new(i, n)
    end
end

# true: [1, 0], false: [0, 1]
LogicalVector(b::Bool) = b ? LogicalVector(1, 2) : LogicalVector(2, 2)

function LogicalVector(bv::BitVector)
    r = LogicalVector(1, 1)
    for b in bv
        r = r * LogicalVector(b)
    end
    return r
end

LogicalVector(bv::AbstractVector{<:Integer}) = LogicalVector(BitVector(bv))

Base.length(lv::LogicalVector) = lv.n
Base.size(lv::LogicalVector) = (length(lv), )
index(lv::LogicalVector) = lv.i

# O(1)
function Base.:*(lv1::LogicalVector, lv2::LogicalVector)
    n0 = (index(lv1) - 1) * length(lv2)
    pos1 = n0 + index(lv2)
    return LogicalVector(pos1, length(lv1) * length(lv2))
end


function Base.isvalid(lv::LogicalVector)
    return 1 <= index(lv) <= length(lv) 
end


# a logical matrix of size `m × n`
mutable struct LogicalMatrix
    i::Vector{Int64}
    m::Int64
    n::Int64

    function LogicalMatrix(i::AbstractVector{<:Integer}, m::Integer, n::Integer)
        @assert all(x -> 1 <= x <= m, i)
        @assert length(i) == n
        new(Int64.(i), m, n)
    end
end

Base.size(lm::LogicalMatrix) = (lm.m, lm.n)
index(lm::LogicalMatrix) = lm.i
Base.ndims(lm::LogicalMatrix) = 2
function Base.size(lm::LogicalMatrix, dim::Integer)
    @assert dim == 1 || dim == 2
    return dim == 1 ? lm.m : lm.n
end


function Base.:*(lm::LogicalMatrix, lv::LogicalVector)
    @assert size(lm, 2) == length(lv)
    # pick the corresponding column
    i = index(lv)
    return LogicalVector(index(lm)[i], size(lm, 1))
end

function Base.isvalid(lm::LogicalMatrix)
    m, n = size(lm)
    return length(index(lm)) == n && all(x->1 <= x <= m, index(lm))
end
