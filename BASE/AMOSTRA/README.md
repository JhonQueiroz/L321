# Amostra da base

Esta pasta contem a amostra inicial usada nos testes.

A amostra foi definida como 30% da base completa em `BASE/FINAL`.
Como a base completa possui 290 grafos, a amostra contem 87 grafos.

## Quantidade proporcional por subfamilia

|   Familia      |  Subfamilia    | Total na base |   Amostra     |
|----------------|----------------|---------------|---------------|
| AS-GRAPHS      | AS-GRAPHS      |      30       |       9       |
| CALMA          | CELAR          |      11       |       3       |
| CALMA          | delft          |      10       |       3       |
| CALMA          | SUBCELAR6      |       5       |       2       |
| CALMA          | SURPRISE       |      14       |       4       |
| CUBIC          | CUBIC          |      39       |      12       |
| DIMACS         | DIMACS         |      71       |      21       |
| HARWELL-BOEING | HARWELL-BOEING |      62       |      19       |
| SMALL-DIAMETER | SMALL-DIAMETER |      48       |      14       |

Total da amostra: 87 grafos.

## Grafos da amostra

### AS-GRAPHS

- `as19980520`
- `as19971109`
- `as19971108`
- `as19980102`
- `as19980325`
- `as19980709`
- `as19981019`
- `as19990225`
- `as19990530`

### CALMA / CELAR

- `celar01`
- `celar02`
- `celar08`

### CALMA / delft

- `TUD200.4`
- `TUD916.1`
- `TUD916.2`

### CALMA / SUBCELAR6

- `CELAR6-SUB1`
- `CELAR6-SUB4`

### CALMA / SURPRISE

- `graph03`
- `graph05`
- `graph09`
- `graph14`

### CUBIC

- `cubic_100`
- `cubic_150`
- `cubic_300`
- `cubic_350`
- `cubic_400`
- `cubic_700`
- `cubic_1000`
- `cubic_1450`
- `cubic_1500`
- `cubic_1800`
- `cubic_1950`
- `cubic_2000`

### DIMACS

- `myciel3`
- `myciel4`
- `MANN_a9`
- `huck`
- `david`
- `C125.9`
- `DSJC125.5`
- `keller4`
- `mulsol.i.5`
- `c-fat200-1`
- `DSJC250.1`
- `fpsol2.i.1`
- `flat300_28_0`
- `fpsol2.i.2`
- `school1`
- `le450_25a`
- `le450_5a`
- `c-fat500-1`
- `c-fat500-5`
- `DSJR500.1`
- `homer`

### HARWELL-BOEING

- `bcspwr01`
- `bcsstk01`
- `bcsstk02`
- `bcsstk08`
- `bcsstk10`
- `bcsstk12`
- `bcsstk21`
- `bcsstk26`
- `nos1`
- `nos3`
- `nos7`
- `can__715`
- `bcsstk19`
- `jagmesh1`
- `sherman1`
- `bcsstm13`
- `blckhole`
- `zenios`
- `mhd3200b`

### SMALL-DIAMETER

- `sd_3_100`
- `sd_3_150`
- `sd_3_200`
- `sd_3_350`
- `sd_3_375`
- `sd_3_475`
- `sd_4_150`
- `sd_4_325`
- `sd_4_475`
- `sd_5_100`
- `sd_5_125`
- `sd_5_225`
- `sd_5_350`
- `sd_5_475`

## Observacao

A selecao dentro de cada subfamilia foi feita usando as metricas do CSV
gerado por `ANALYSIS/analyze_graphs.jl`, buscando diversidade em numero de
vertices, numero de arestas, densidade, grau maximo e diametro.
