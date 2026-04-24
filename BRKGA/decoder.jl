function l321_decode!(chromosome::Vector{Float64}, instance::L321_Instance, rewrite::Bool)::Float64
    order = sortperm(chromosome)
     _, span = greedy_l321(instance.graph, order, instance.distsets)
     return span
end
