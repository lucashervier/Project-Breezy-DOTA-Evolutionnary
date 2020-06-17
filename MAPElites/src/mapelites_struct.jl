using Cambrian
export MapElites
struct SparseArray{T,N} <: AbstractArray{T,N}
          data::Dict{NTuple{N,Int}, T}
          dims::NTuple{N,Int}
end

SparseArray(::Type{T}, dims::Int...) where {T} = SparseArray(T, dims)
SparseArray(::Type{T}, dims::NTuple{N,Int}) where {T,N} = SparseArray{T,N}(Dict{NTuple{N,Int}, T}(), dims)
Base.size(A::SparseArray) = A.dims
Base.similar(A::SparseArray, ::Type{T}, dims::Dims) where {T} = SparseArray(T, dims)
Base.getindex(A::SparseArray{T,N}, I::Vararg{Int,N}) where {T,N} = get(A.data, I, zero(T))
Base.setindex!(A::SparseArray{T,N}, v, I::Vararg{Int,N}) where {T,N} = (A.data[I] = v)
Base.zero(Ind::Type{Individual}) = missing
Base.zero(elt::Type{Union{Missing, Array{Float64,N} where N}}) = missing

struct MapElites
    feature_dimension::Int64
    grid_mesh::Int64
    solutions::SparseArray{Union{Missing,Individual}}
    performances::SparseArray{Union{Missing,Array{Float64}}}
end

function MapElites(f_dim::Int64,g_size::Int64)
    feature_dimension = f_dim
    grid_mesh = g_size
    size_map = Tuple([g_size for i in 1:f_dim])
    solutions = SparseArray(Union{Missing,Individual},size_map)
    performances = SparseArray(Union{Missing,Array{Float64}},size_map)
    MapElites(feature_dimension,grid_mesh,solutions,performances)
end
