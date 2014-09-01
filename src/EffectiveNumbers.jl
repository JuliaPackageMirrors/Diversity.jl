## powermean - Calculate order-th power mean of values, weighted by weights
## By default, weights are equal and order is 1, so this is just the arithmetic mean
##
## Arguments:
## - values - values for which to calculate mean
## - order - order of power mean
## - weights - weights of elements, normalised to 1 inside function
##
## Returns:
## - weighted power mean
function powermean{S <: Number, T <: Number, U <: Number}(values::Vector{S},
                   order::T = 1,
                   weights::Vector{U} = ones(FloatingPoint, size(values)))
    ## Normalise weights to sum to 1 (as per Rényi)
    length(values) == length(weights) ||
    error("Weight and value vectors must be the same length")
    proportions = weights / sum(weights)
    power = convert(FloatingPoint, order)
    present = filter(x -> !isapprox(x[1], 0), zip(proportions, values))
    if (isinf(power))
        if (power > 0) # +Inf -> Maximum
            reduce((a, b) -> a[2] > b[2] ? a : b, present)[2]
        else # -Inf -> Minimum
            reduce((a, b) -> a[2] < b[2] ? a : b, present)[2]
        end
    else
        if (isapprox(power, 0))
            mapreduce((pair) -> pair[2] ^ pair[1], *, present)
        else
            mapreduce(pair -> pair[1] * pair[2] ^ power, +,
                      present) ^ (1 / power)
        end
    end
end

function powermean{S <: Number, T <: Number, U <: Number}(values::Vector{S},
                   orders::Vector{T},
                   weights::Vector{U} = ones(FloatingPoint, size(values)))
    map((order) ->  powermean(values, order, weights), orders)
end

## qD - calculate Hill number / naive diversity of order q of a
## population with given relative proportions
##
## Arguments:
## - proportions - relative proportions of different individuals /
##                 species in population
## - qs - single number or vector of orders of diversity measurement
function qD{S <: FloatingPoint}(proportions::Vector{S}, qs)
  powermean(proportions, qs - 1., proportions) .^ -1
end

## qD - calculate Hill number / naive diversity of order q of a
## population with given relative proportions
##
## Arguments:
## - proportions - relative proportions of different individuals /
##                 species in population
## - qs - single number or vector of orders of diversity measurement
function qD{S <: FloatingPoint}(proportions::Matrix{S}, qs)
    mapslices((p) ->  qD(p, qs), proportions, 1)
end

## qDZ - calculate Leinster-Cobbold general diversity of >= 1 order q
## of a population with given relative proportions, and similarity
## matrix Z
##
## Arguments:
## - proportions - relative proportions of different individuals /
##                 species in population
## - qs - single number or vector of orders of diversity measurement
## - Z - similarity matrix
function qDZ{S <: FloatingPoint}(proportions::Vector{S}, qs,
                                 Z::Matrix{S} = eye(length(proportions)))
    l = length(proportions)
    size(Z) == (l, l) ||
    error("Similarity matrix size does not match species number")
    powermean(Z * proportions, qs - 1., proportions) .^ -1
end

## qDZ - calculate general Leinster-Cobbold diversity of >= 1 order q
## of a population with given relative proportions, and similarity
## matrix Z
##
## Arguments:
## - proportions - relative proportions of different individuals /
##                 species in population
## - qs - single number or vector of orders of diversity measurement
## - Z - similarity matrix
function qDZ{S <: FloatingPoint}(proportions::Matrix{S}, qs,
                                 Z::Matrix{S} = eye(size(proportions)[1]))
    mapslices((p) ->  qDZ(p, qs, Z), proportions, 1)
end
