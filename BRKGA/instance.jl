using Graphs

struct L321_Instance <: AbstractInstance
    graph::AbstractGraph
    num_nodes::Int64
    distsets
end

function read_graph(filename::String)
    open(filename, "r") do io
        n, m = parse.(Int, split(strip(readline(io))))
        g = SimpleGraph(n)

        for line in eachline(io)
            u, v = parse.(Int, split(line))
            u == v && continue
            add_edge!(g, u, v)
        end
        return g
    end
end

function L321_Instance(filename::String)
    g = read_graph(filename)
    distsets = precompute_distsets(g)
    return L321_Instance(g, nv(g), distsets)                       
end
