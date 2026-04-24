# GA-L321

Algoritmo genetico para o Problema da Rotulacao L(3,2,1) em grafos.

Este projeto implementa um algoritmo genetico baseado em permutacao (PBGA), usando um algoritmo guloso como funcao de avaliacao. O fitness de cada individuo e o `span` da rotulacao produzida, isto e, o maior rotulo atribuido. O objetivo e minimizar esse valor.

## Caracteristicas

- Representacao por permutacao dos vertices.
- Selecao por torneio binario (`k = 2`) como operador padrao.
- Cruzamento Order Crossover (`OX`) de dois pontos como operador padrao.
- Mutacao por troca (`swap`) como operador padrao.
- Elitismo com preservacao parcial da populacao.
- Pre-calculo dos conjuntos de vertices a distancia 1, 2 e 3.
- Execucoes independentes por instancia, com exportacao de resultados em CSV.

O codigo tambem contem operadores alternativos:

- Selecao por roleta em [GA/selection_ops.jl](GA/selection_ops.jl).
- Cruzamento PMX em [GA/crossover_ops.jl](GA/crossover_ops.jl).
- Mutacao por inversao em [GA/mutation_ops.jl](GA/mutation_ops.jl).

## Requisitos

O projeto foi desenvolvido em Julia e depende dos pacotes declarados em [Project.toml](Project.toml):

- `Graphs.jl`
- `ArgParse.jl`
- `CSV.jl`
- `DataFrames.jl`

`Random` e `Base.Threads` fazem parte da biblioteca padrao do Julia.

## Ambiente Julia

Com Julia instalado, entre na pasta do projeto e ative o ambiente local:

```bash
julia --project=.
```

Na primeira execucao, resolva e instale as dependencias:

```bash
julia --project=. -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
```

Esse comando tambem preenche o [Manifest.toml](Manifest.toml) com as versoes exatas dos pacotes instalados. O `Project.toml` declara as dependencias diretas do projeto; o `Manifest.toml` registra a resolucao completa para tornar os experimentos mais reprodutiveis.

## Estrutura do projeto

- `BASE/`: conjunto completo de instancias.
- `GA/main.jl`: script principal de linha de comando.
- `GA/ga.jl`: implementacao do algoritmo genetico.
- `GA/selection_ops.jl`: operadores de selecao.
- `GA/crossover_ops.jl`: operadores de cruzamento.
- `GA/mutation_ops.jl`: operadores de mutacao.
- `GREEDY/greedy.jl`: algoritmo guloso L(3,2,1) e pre-calculo de distancias.
- `RESULTS/GA/`: resultados do algoritmo genetico principal.
- `RESULTS/BRKGA/`: resultados do BRKGA.
- `run_ga.ps1`: script de execucao em lote do GA para PowerShell no Windows.
- `run_brkga.ps1`: script de execucao em lote do BRKGA para PowerShell no Windows.

## Formato das instancias

As instancias sao arquivos `.txt` em formato de lista de arestas:

```text
n m
u1 v1
u2 v2
...
um vm
```

A primeira linha contem o numero de vertices `n` e o numero de arestas `m`. As linhas seguintes contem uma aresta por linha.

## Execucao de uma instancia

Exemplo:

```bash
julia --project=. --threads auto GA/main.jl \
  --instance BASE/sd_3_100.txt \
  --seed 1234 \
  --pop_factor 2 \
  --crossover_rate 0.90 \
  --mutation_rate 0.20 \
  --elitism_rate 0.10 \
  --max_gen 200 \
  --trials 30 \
  --output RESULTS/GA/sd_3_100.csv
```

O script gera dois arquivos:

- `sd_3_100.csv`: resumo por tentativa independente.
- `sd_3_100_curve.csv`: melhor `span` por geracao em cada tentativa.

## Execucao em lote

### Windows / PowerShell

No Windows, use o script [run_ga.ps1](run_ga.ps1). Ele percorre recursivamente as instancias `.txt`,
cria a mesma estrutura de subpastas em `RESULTS/GA` e pula instancias que ja possuem CSV de saida.

Execucao padrao, usando `BASE/` como entrada:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_ga.ps1
```

Parametros principais do script:

- `-BaseDir`: pasta raiz das instancias. Padrao: `BASE`.
- `-RootOutputDir`: pasta raiz dos resultados. Padrao: `RESULTS\GA`.
- `-JuliaThreads`: numero de threads usado por `julia --threads`. Padrao: `auto`.
- `-Seed`: semente base. Padrao: `1234`.
- `-PopFactor`: denominador para `popsize = floor(n/pop_factor)`. Padrao: `2`.
- `-CrossoverRate`: taxa de cruzamento. Padrao: `0.90`.
- `-MutationRate`: taxa de mutacao. Padrao: `0.20`.
- `-ElitismRate`: taxa de elitismo. Padrao: `0.10`.
- `-MaxGen`: numero maximo de geracoes. Padrao: `200`.
- `-Trials`: numero de execucoes independentes por instancia. Padrao: `30`.

O script procura `julia` no `PATH`. Se o `PATH` apontar apenas para o alias do
`Microsoft\WindowsApps`, ele tambem tenta localizar o executavel instalado pelo `juliaup`
em `$HOME\.julia\juliaup`.

### BRKGA / PowerShell

Para o BRKGA, use [run_brkga.ps1](run_brkga.ps1). Ele percorre recursivamente as instancias `.txt`,
grava um CSV por instancia em `RESULTS/BRKGA` e pula instancias que ja possuem arquivo de saida.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_brkga.ps1
```

## Observacoes

- O projeto ainda nao possui testes automatizados.
- Para reproduzir resultados em outra maquina, mantenha o `Project.toml` e gere/compartilhe um `Manifest.toml` completo a partir do comando de ambiente Julia.
