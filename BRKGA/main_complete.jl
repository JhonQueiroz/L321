using BrkgaMpIpr
using Base.Threads

import Base: parse
import Dates
import Random
using Printf

include("../GREEDY/greedy.jl")
include("instance.jl")
include("decoder.jl")

################################################################################
# Regras de parada
################################################################################
"""

@enum StopRule

Controla os critérios de parada. A execução para quando:
- um determinado número de `GERAÇÕES` for atingido;
- ou um valor `ALVO` for encontrado;
- ou nenhuma `MELHORIA` for encontrada em um determinado número de iterações.
"""

@enum StopRule begin
    GENERATIONS = 0
    TARGET = 1
    IMPROVEMENT = 2
end

function parse(::Type{StopRule}, value::String)::StopRule
    local_value = uppercase(strip(value)[1])

    if local_value == 'G'
        return GENERATIONS
    elseif local_value == 'T'
        return TARGET
    elseif local_value == 'I'
        return IMPROVEMENT
    end

    throw(ArgumentError("Regra de parada invalida: $value"))
end

################################################################################
# Leitura de argumentos
################################################################################

function print_help()
    println("""
Uso:
  julia --project=BRKGA BRKGA/main_complete.jl -c <config_file> -s <seed> -r <stop_rule> -a <stop_arg> -t <max_time> -i <instance_file> [--no_evolution]

Opcoes:
  -c <config_file>    Arquivo de configuracao do BRKGA.
  -s <seed>           Semente do gerador aleatorio.
  -r <stop_rule>      Regra de parada: G=geracoes, I=sem melhoria, T=alvo.
  -a <stop_arg>       Valor associado a regra de parada.
  -t <max_time>       Tempo maximo em segundos.
  -i <instance_file>  Arquivo da instancia.
  --no_evolution      Desativa operadores evolutivos.
  -h, --help          Mostra esta ajuda.
""")
end

function parse_command_line(argv::Vector{String})
    args = Dict{String, String}()
    args["--no_evolution"] = "false"

    i = 1
    while i <= length(argv)
        arg = argv[i]

        if arg == "-h" || arg == "--help"
            print_help()
            exit(0)
        elseif arg == "--no_evolution"
            args["--no_evolution"] = "true"
            i += 1
        elseif arg in ["-c", "-s", "-r", "-a", "-t", "-i"]
            i == length(argv) && error("Valor ausente para o argumento $arg")
            args[arg] = argv[i + 1]
            i += 2
        else
            error("Argumento desconhecido: $arg")
        end
    end

    for required_arg in ["-c", "-s", "-r", "-a", "-t", "-i"]
        haskey(args, required_arg) || error("Argumento obrigatorio ausente: $required_arg")
    end

    return args
end

################################################################################
# Funcoes auxiliares do L(3,2,1)
################################################################################

function initial_order_by_degree(instance::L321_Instance)
    degrees = [degree(instance.graph, v) for v in 1:instance.num_nodes]
    return sortperm(degrees; rev=true)
end

function order_to_chromosome(order::Vector{Int}, seed::Int)
    Random.seed!(seed)
    keys = sort(rand(length(order)))
    chromosome = zeros(length(order))

    for i in eachindex(order)
        chromosome[order[i]] = keys[i]
    end

    return chromosome
end

function chromosome_to_order(chromosome::Vector{Float64})
    pairs = Array{Tuple{Float64, Int64}}(undef, length(chromosome))

    for (index, key) in enumerate(chromosome)
        pairs[index] = (key, index)
    end

    sort!(pairs)
    return [node for (_, node) in pairs]
end

################################################################################
# Execucao principal
################################################################################

function main(args)
    configuration_file = args["-c"]
    instance_file = args["-i"]
    seed = parse(Int64, args["-s"])
    stop_rule = parse(StopRule, args["-r"])

    if stop_rule == TARGET
        stop_argument = parse(Float64, args["-a"])
    else
        stop_argument = parse(Int64, args["-a"])
    end

    maximum_time = parse(Float64, args["-t"])
    maximum_time <= 0.0 && error("O tempo maximo deve ser maior que zero. Valor recebido: $maximum_time.")

    perform_evolution = args["--no_evolution"] != "true"

    ########################################
    # Carrega configuracao e exibe parametros
    ########################################

    brkga_params, control_params = load_configuration(configuration_file)

    print("""
    ------------------------------------------------------
    > Experimento iniciado em $(Dates.now())
    > Instancia: $instance_file
    > Configuracao: $configuration_file
    > Parametros do algoritmo:
    """)

    if !perform_evolution
        println(">    - Multi-start simples: ligado (sem operadores evolutivos)")
    else
        output_string = ""
        for field in fieldnames(BrkgaParams)
            output_string *= ">  - $field $(getfield(brkga_params, field))\n"
        end
        for field in fieldnames(ExternalControlParams)
            output_string *= ">  - $field $(getfield(control_params, field))\n"
        end
        print(output_string)
        println("""
        > Semente: $seed
        > Regra de parada: $stop_rule
        > Argumento da parada: $stop_argument
        > Tempo maximo (s): $maximum_time
        > Threads para decodificacao: $(nthreads())
        ------------------------------------------------------""")
    end

    ########################################
    # Carrega instancia e cria solucao inicial
    ########################################

    println("\n[$(Dates.Time(Dates.now()))] Lendo dados L(3,2,1)...")

    instance = L321_Instance(instance_file)
    println("Numero de vertices: $(instance.num_nodes)")

    println("\n[$(Dates.Time(Dates.now()))] Gerando ordem inicial...")

    initial_order = initial_order_by_degree(instance)
    _, initial_span = greedy_l321(instance.graph, initial_order, instance.distsets)
    println("Span inicial: $initial_span")

    ########################################
    # Constroi e inicializa o BRKGA
    ########################################

    println("\n[$(Dates.Time(Dates.now()))] Construindo estrutura BRKGA...")

    brkga_params.population_size = min(brkga_params.population_size,
                                       10 * instance.num_nodes)
    println("Novo tamanho da populacao: $(brkga_params.population_size)")

    brkga_data = build_brkga(instance, l321_decode!, MINIMIZE, seed,
                            instance.num_nodes, brkga_params, perform_evolution)

    # Viés padrao do BRKGA com um pai elite e um pai nao elite.
    rho = 0.75
    set_bias_custom_function!(brkga_data, x -> x == 1 ? rho : 1.0 - rho)

    initial_chromosome = order_to_chromosome(initial_order, seed)
    set_initial_population!(brkga_data, [initial_chromosome])

    println("\n[$(Dates.Time(Dates.now()))] Inicializando BRKGA...")
    initialize!(brkga_data)

    ########################################
    # Aquecimento fora da medicao
    ########################################

    println("\n[$(Dates.Time(Dates.now()))] Aquecendo codigo...")

    bogus_data = deepcopy(brkga_data)
    evolve!(bogus_data, 2)
    get_best_fitness(brkga_data)
    get_best_chromosome(brkga_data)
    bogus_data = nothing

    ########################################
    # Evolucao
    ########################################

    println("\n[$(Dates.Time(Dates.now()))] Evoluindo...")
    println("* Iteracao | Span | TempoAtual")

    best_span = Inf
    best_chromosome = initial_chromosome

    iteration = 0
    last_update_time = 0.0
    last_update_iteration = 0
    large_offset = 0
    path_relink_time = 0.0
    num_path_relink_calls = 0
    num_homogenities = 0
    num_best_improvements = 0
    num_elite_improvements = 0
    run = true
    start_time = time()

    while run
        iteration += 1

        evolve!(brkga_data)

        fitness = get_best_fitness(brkga_data)
        if fitness < best_span
            last_update_time = time() - start_time
            update_offset = iteration - last_update_iteration

            if large_offset < update_offset
                large_offset = update_offset
            end

            last_update_iteration = iteration
            best_span = fitness
            best_chromosome = get_best_chromosome(brkga_data)

            @printf("* %d | %.0f | %.2f \n", iteration, best_span,
                    last_update_time)
        end

        iter_without_improvement = iteration - last_update_iteration

        # IPR fica inativo quando exchange_interval = 0 no arquivo de configuracao.
        if control_params.exchange_interval > 0 &&
           iter_without_improvement > 0 &&
           (iter_without_improvement % control_params.exchange_interval == 0)

            println("Executando path relink na iteracao $iteration...")
            num_path_relink_calls += 1

            pr_now = time()
            result = path_relink!(
                brkga_data,
                brkga_params.pr_type,
                brkga_params.pr_selection,
                kendall_tau_distance,
                affect_solution_kendall_tau,
                brkga_params.pr_number_pairs,
                brkga_params.pr_minimum_distance,
                1,
                maximum_time - (time() - start_time),
                brkga_params.pr_percentage
            )

            pr_time = time() - pr_now
            path_relink_time += pr_time

            if result == TOO_HOMOGENEOUS
                num_homogenities += 1
                println("- Populacoes muito homogeneas | Tempo: $(@sprintf("%.2f", pr_time))")
            elseif result == NO_IMPROVEMENT
                println("- Nenhuma melhoria encontrada | Tempo: $(@sprintf("%.2f", pr_time))")
            elseif result == ELITE_IMPROVEMENT
                num_elite_improvements += 1
                println("- Melhoria no conjunto elite | Tempo: $(@sprintf("%.2f", pr_time))")
            elseif result == BEST_IMPROVEMENT
                num_best_improvements += 1
                fitness = get_best_fitness(brkga_data)
                println("- Melhoria no melhor individuo: $fitness | Tempo: $(@sprintf("%.2f", pr_time))")

                if fitness < best_span
                    last_update_time = time() - start_time
                    update_offset = iteration - last_update_iteration

                    if large_offset < update_offset
                        large_offset = update_offset
                    end

                    last_update_iteration = iteration
                    best_span = fitness
                    best_chromosome = get_best_chromosome(brkga_data)

                    @printf("* %d | %.0f | %.2f \n", iteration, best_span,
                            last_update_time)
                end
            end
        end

        run = !(
            (time() - start_time > maximum_time) ||
            (stop_rule == GENERATIONS && Float64(iteration) == stop_argument) ||
            (stop_rule == IMPROVEMENT &&
             Float64(iter_without_improvement) >= stop_argument) ||
            (stop_rule == TARGET && best_span <= stop_argument)
        )
    end

    total_elapsed_time = time() - start_time
    total_num_iterations = iteration

    println("[$(Dates.Time(Dates.now()))] Fim da otimizacao")
    print("\nTotal de iteracoes: $total_num_iterations")
    print("\nUltima iteracao com melhoria: $last_update_iteration")
    @printf("\nTempo total de otimizacao: %.2f", total_elapsed_time)
    @printf("\nTempo da ultima melhoria: %.2f", last_update_time)
    print("\nMaior intervalo entre melhorias: $large_offset")

    @printf("\nTempo total de path relink: %.2f", path_relink_time)
    print("\nChamadas de path relink: $num_path_relink_calls")
    print("\nNumero de homogeneidades: $num_homogenities")
    print("\nMelhorias no conjunto elite: $num_elite_improvements")
    print("\nMelhorias no melhor individuo: $num_best_improvements")

    best_order = chromosome_to_order(best_chromosome)

    print("\n\n% Melhor span: $(@sprintf("%.0f", best_span))")
    print("\n% Melhor ordem: ")
    for node in best_order
        print("$node ")
    end

    println("\n\nInstance,Seed,NumNodes,TotalIterations,TotalTime," *
            "TotalPRTime,PRCalls,NumHomogenities,NumPRImprovElite," *
            "NumPrImprovBest,LargeOffset,LastUpdateIteration,LastUpdateTime," *
            "BestSpan")
    print("$(basename(instance_file))," *
          "$seed,$(instance.num_nodes),$total_num_iterations," *
          "$(@sprintf("%.2f", total_elapsed_time))," *
          "$(@sprintf("%.2f", path_relink_time))," *
          "$num_path_relink_calls,$num_homogenities,$num_elite_improvements," *
          "$num_best_improvements,$large_offset,$last_update_iteration," *
          "$(@sprintf("%.2f", last_update_time))," *
          "$(@sprintf("%.0f", best_span))")

    nothing
end

main(parse_command_line(ARGS))
