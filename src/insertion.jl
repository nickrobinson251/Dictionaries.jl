# Insertable maps can have both keys and values that mutate
#
# TODO: define functions like `empty` that guarantee an insertable dictionary.
#
#    - empty_insertable(input) - no keys or values
#    - similar_insertable(input) - same keys, undef values
#    - copy_insertable(input) - same keys and values
#
# Also, need same for indices (with either dictionary or indices outputs)

"""
    isinsertable(dict::AbstractDictionary)

Return `true` if `dict` supports the insertable interface, or `false` otherwise. The primary
functions `dict` needs to implement for the insertable interface are:
 
 * `insert!(dict, i, value)` - add a new `value` at index `i` (will error if index exists)
 * `delete!(dict, i)` - remove element at index `i` (will error if index does not exist)

Functions `get!`, `set!` and `unset!` are also provided for common operations where you are
not sure if an index exists or not.
"""
isinsertable(::AbstractDictionary) = false

"""
    isinsertable(indices::AbstractIndices)

Return `true` if `indices` supports the insertable interface, or `false` otherwise. The
primary functions a map needs to implement for the insertable interface are:
 
 * `insert!(indices, i)` - add new index `i` to `indices` (will error if index exists)
 * `delete!(indices, i)` - remove an existing index `i` from `indices` (will error if index does not exist).

Functions `set!` and `unset!` are also provided for common operations where you are not sure
if an index exists or not.
"""
isinsertable(::AbstractIndices) = false

### Scalar insertion/deletion

"""
    insert!(indices::AbstractIndices, i)

Insert the new index `i` into `indices`. An error is thrown if `i` already exists.
"""
@propagate_inbounds function Base.insert!(indices::AbstractIndices{I}, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return insert!(indices, i2)
end

function Base.insert!(indices::AbstractIndices{I}, ::I) where {I}
    if isinsertable(indices)
        error("insert! needs to be defined for insertable indices: $(typeof(indices))")
    else
        error("indices not insertable: $(typeof(indices))")
    end
end

"""
    insert!(dict::AbstractDictionary, value, i)

Insert the `value` at new index `i` into `dict`. An error is thrown if index `i` already
exists. 

Hint: Use `setindex!` to update an existing value, and `set!` to perform an "upsert"
(update-or-insert) operation.
"""
@propagate_inbounds function Base.insert!(d::AbstractDictionary{I}, value, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return insert!(d, value, i2)
end

function Base.insert!(d::AbstractDictionary{I, T}, value, i::I) where {I, T}
    return insert!(d, convert(T, value), i)
end

function Base.insert!(d::AbstractDictionary{I, T}, ::T, ::I) where {I, T}
    if isinsertable(d)
        error("insert! needs to be defined for insertable dictionary: $(typeof(d))")
    else
        error("dictionary not insertable: $(typeof(d))")
    end
end

"""
    set!(dict::AbstractDictionary, value, i)

Update or insert the `value` at index `i` into `dict`. Sometimes referred to as an "upsert"
operation.

Hint: Use `setindex!` to exclusively update an existing value, and `insert!` to exclusively
insert a new value. See also `get!`.
"""
@propagate_inbounds function set!(d::AbstractDictionary{I}, value, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return set!(d, value, i2)
end

function set!(d::AbstractDictionary{I, T}, value, i::I) where {I, T}
    return set!(d, convert(T, value), i)
end

function set!(d::AbstractDictionary{I, T}, value::T, i::I) where {I, T}
    if haskey(d, i)
        @inbounds d[i] = value
    else
        insert!(d, value, i)
    end
    return d
end

"""
    set!(indices::AbstractIndices, i)

Insert a new value `i` into `indices` if it doesn't exist, or do nothing otherwise.
"""
@propagate_inbounds function set!(indices::AbstractIndices{I}, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return set!(indices, i2)
end

function set!(indices::AbstractIndices{I}, i::I) where {I}
    if i ∉ indices
        insert!(indices, i)
    end
    return indices
end

"""
    get!(dict::AbstractDictionary, i, default)

Return the value `dict[i]` if index `i` exists. Otherwise, a new index `i` is inserted and
set to `default`, which is returned.

See also `get`, `set!`.
"""
@propagate_inbounds function Base.get!(d::AbstractDictionary{I}, i, default) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return get!(d, i2, default)
end

function Base.get!(d::AbstractDictionary{I, T}, i::I, default) where {I, T}
    return get!(d, i, convert(T, default))
end

function Base.get!(d::AbstractDictionary{I, T}, i::I, default::T) where {I, T}
    if haskey(d, i)
        return @inbounds d[i]
    else
        insert!(d, default, i)
        return default
    end
end

# TODO: the`get!(f, dict, i)` form

"""
    delete!(indices::AbstractIndices, i)

Delete the index `i` from `indices`. An error is thrown if `i` does not exist.

    delete!(dict::AbstractDictionary, i)

Delete the index `i` from `dict`. An error is thrown if `i` does not exist.

See also `unset!`, `insert!`.
"""
@propagate_inbounds function Base.delete!(d::AbstractDictionary{I}, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return delete!(d, i2)
end

function Base.delete!(d::AbstractDictionary{I}, ::I) where {I}
    if isinsertable(d)
        error("delete! needs to be defined for insertable dictionary: $(typeof(d))")
    else
        error("dictionary is not insertable: $(typeof(d))")
    end
end


"""
    unset!(indices::AbstractIndices, i)

Delete the index `i` from `indices` if it exists, or do nothing otherwise.

    unset!(dict::AbstractDictionary, i)

Delete the index `i` from `dict` if it exists, or do nothing otherwise.

See also `delete!`, `set!`.
"""
@propagate_inbounds function unset!(indices::AbstractDictionary{I}, i) where {I}
    i2 = convert(I, i)
    if !isequal(i, i2)
        throw(ArgumentError("$i is not a valid key for type $I"))
    end
    return unset!(indices, i2)
end

function unset!(d::AbstractDictionary{I}, i::I) where {I}
    if i ∈ keys(d)
        delete!(d, i)
    end
    return d
end

### Non-scalar insertion/deletion

Base.merge!(d::AbstractDictionary, ds::AbstractDictionary...) = merge!(last, d, ds...)

function Base.merge!(combiner::Function, d::AbstractDictionary, d2::AbstractDictionary)
    for (i, v) in pairs(d2)
        if haskey(d, i)
            d[i] = combiner((d[i], v))
        else
            insert!(d, v, i)
        end
    end
    return d
end

function Base.merge!(::typeof(last), d::AbstractDictionary, d2::AbstractDictionary)
    for (i, v) in pairs(d2)
        set!(d, v, i)
    end
    return d
end

function Base.merge!(::typeof(first), d::AbstractDictionary, d2::AbstractDictionary)
    for (i, v) in pairs(d2)
        get!(d, i, v)
    end
    return d
end

function Base.merge!(combiner::Function, d::AbstractDictionary, d2::AbstractDictionary, ds::AbstractDictionary...)
    merge!(combiner, merge!(combiner, d, d2), ds...)
end

function Base.merge!(::typeof(last), d::AbstractIndices, d2::AbstractIndices)
    union!(d, d2)
end

# TODO some kind of exclusive merge (throw on key clash like `insert!`)

# TODO: deletemany!, unsetmany! (which is setdiff! on indices)

### Indices ("sets") versions of above

function Base.union!(s1::AbstractIndices, s2::AbstractIndices)
    for i in s2
        set!(s1, i)
    end
    return s1
end

function Base.intersect!(s1::AbstractIndices, s2::AbstractIndices)
    for i in s1
        if i ∉ s2
            delete!(s1, i)
        end
    end
    return s1
end

function Base.setdiff!(s1::AbstractIndices, s2::AbstractIndices)
    for i in s2
        unset!(s1, i)
    end
    return s1
end

function Base.symdiff!(s1::AbstractIndices, s2::AbstractIndices)
    for i in s2
        if i in s1
            delete!(s1, i)
        else
            insert!(s1, i)
        end
    end
    return s1
end

# `filter!` is basically a programmatic version of `intersect!`. 
function Base.filter!(f, indices::AbstractIndices)
    for i in indices
        if !f(i)
            delete!(indices, i)
        end
    end
    return indices
end