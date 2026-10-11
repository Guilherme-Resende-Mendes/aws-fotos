# HD 1 — HD NG 22

Disco **1** na ordem em que o Guilherme ligou. Lido em 9 de outubro de 2026. Volume `D:`, rótulo **HD NG 22**, Seagate, NTFS, 931 GB, 125 GB livres. O acervo está em `D:\2022`: **175.025 arquivos, 757 GB**. O resto da raiz é instalador e ícone do Seagate.

Este HD é o ano de 2022. O disco 2 é o Seagate de 2018–2021, em [seagate-expansion-drive.md](hds/seagate-expansion-drive.md). A organização muda de um disco para o outro.

## Duas organizações do mesmo ano

O ano não está numa árvore só. Há um corte por mês e outro por cliente.

```
2022/
  01 - JANEIRO/ ... 12 - DEZEMBRO/     sessão a sessão, na ordem do calendário
  2022 CLIENTES/                       o mesmo trabalho, agrupado por cliente
  DIA DAS MÃES/                        evento fora do mês
  nanda pessoal/                       arquivo pessoal, não é cliente
  presets/                             .xmp do Lightroom
  POS/                                 sobra solta de JPG
```

### Por mês

`MM - MÊS / NOME + tipo de sessão /`

160 pastas de sessão nos doze meses. O sufixo `ok` aparece pouco e não serve de status.

Dentro da sessão, o que se repete:

| O que | Onde | Neste disco |
| --- | --- | --- |
| Export editado | pasta `POS/` | 138 sessões têm `POS` na raiz. JPG renomeado, na casa de 4–6 MB |
| JPEG da câmera | solto na sessão, `IMG_####.JPG` | ~4 MB. Não está em toda sessão |
| RAW | `IMG_####.CR2` | só em maio: 2.313 arquivos, 52 GB |
| Vídeo de câmera | `MVI_####.MOV` | espalhado em alguns meses |
| Outra tomada | subpasta extra com nome da sessão | 27 casos |

Maio sozinho tem 104 GB por causa do CR2. Abril tem 6 GB. A média da sessão fica em cerca de 4 GB, com ponta muito acima disso quando entra RAW ou vídeo.

### Por cliente

`2022 CLIENTES / CLIENTE / sessão / pasta com o export`

28 clientes, 108 GB. Uma cliente junta gestante, newborn, meses e 1 ano — o ciclo que a reunião descreveu.

Aqui mora o que o corte mensal não organiza:

- JPG grande (edição, 49 GB) e JPG pequeno, abaixo de 1,5 MB (19 GB, 25 mil arquivos)
- 1.084 vídeos `.mov`
- `.psd` de quadro (15×21, 20×30) — peça de álbum, não foto de sessão
- `.veg` de projeto de vídeo

## Volume por tipo

| Extensão | Arquivos | Volume |
| --- | --- | --- |
| `.jpg` | 169.365 | 615 GB |
| `.mov` | 2.857 | 89 GB |
| `.cr2` | 2.313 | 52 GB |
| resto (`.mp4`, `.psd`, `.png`, `.zip`, `.xmp`) | — | < 1 GB |

| Pasta | Volume |
| --- | --- |
| 12 meses | 603 GB |
| `2022 CLIENTES` | 108 GB |
| `DIA DAS MÃES` | 24 GB |
| `nanda pessoal` | 21 GB |

Dos JPEG, 539 GB estão nos meses em arquivo grande. Os 19 GB pequenos estão quase todos em `2022 CLIENTES`.

## O que sobe

O disco inteiro. Sem filtro de tipo e sem descarte de pasta.

No calendário a unidade continua sendo a sessão: `2022 / MM - MÊS / sessão /`, com RAW, JPEG, `POS/` e vídeo. As outras pastas sobem como estão: `2022 CLIENTES`, `DIA DAS MÃES`, `nanda pessoal`, `presets` e a `POS` solta na raiz do ano. As duas árvores sobem as duas, mesmo se o mesmo trabalho aparecer nos dois lugares.

Neste disco isso é os 757 GB de `D:\2022`. Ficam de fora só os arquivos do próprio Seagate na raiz do volume (`Start_Here`, `Warranty.pdf`, `Autorun`).

Em 09/10/2026, por volta de 11:49, o HD NG 22 não estava conectado. Os números abaixo são da leitura da manhã, com o disco em `D:`. Nenhum outro HD do estúdio foi lido.

## Custo deste disco

757 GB em Deep Archive ou Azure Archive LRS, tabela do Leste dos EUA: cerca de **US$ 0,75 por mês**, **US$ 9 por ano**. Uma consulta de 15 GB no Standard da AWS fica em cerca de US$ 0,30.

Os 8 TB da reunião ainda não foram medidos. Se os outros discos forem parecidos com este, oito HDs dariam cerca de 6 TB e uns US$ 6 por mês. Isso é projeção, não leitura.

## Como puxar um cliente

O zip continua sendo a sessão. O que muda é o índice, não o corte do arquivo.

Um zip por cliente não serve. `2022 CLIENTES` tem 28 pastas e 108 GB, média de cerca de 4 GB, mas o calendário tem 160 sessões e 603 GB. A maior parte do ano não está na pasta de clientes. Maio sozinho tem 104 GB. Juntar o ano de uma cliente num arquivo só mistura as duas árvores e estoura os 15 GB de uma consulta.

Um zip por mês também não serve. Para achar uma cliente seria preciso restaurar o mês inteiro.

A divisão que permite puxar a cliente sem baixar o disco:

- Cada pasta de sessão vira um zip no caminho em que já está: `2022 / mês / sessão.zip` e `2022 CLIENTES / cliente / sessão.zip`.
- Um índice ao lado lista, para cada zip, o nome da pasta, o mês ou o cliente, o tamanho e o checksum.
- O pedido de uma cliente é um filtro nesse índice. Voltam só as sessões daquele nome, uma de cada vez, de dentro dos 15 GB.

O nome da pasta é a chave. No calendário ele traz a pessoa e o tipo da sessão juntos (`gestante`, `newborn`, mês). Não dá para fundir isso com `2022 CLIENTES` por programa sem conferir sessão a sessão. As duas árvores sobem as duas.

## De onde saiu “não salvar RAW”

Da transcrição de 24/08/2026, na fala de quem opera o estúdio: subiria para a nuvem as fotos editadas (cerca de 200 por cliente, não os 600 a 1.200 cliques) e, dali para a frente, a câmera passou a gravar JPEG porque o JPEG bastava para a entrega. Eu tratei isso como regra do acervo antigo. Em 09/10/2026 o Guilherme corrigiu: salva por sessão, o RAW entra, e entra tudo o que está nos HDs.

## Envio para o Azure

Começou em outro PC, que subiu 57.591 arquivos (258 GB) para `acervo/hd-ng-22` até 10/10/2026 de manhã. Continua neste PC desde 10/10 às 23:14, como `F:`, por [upload-ciclos.ps1](../scripts/upload-ciclos.ps1): cópia nova sem reenviar o que já existe, concorrência 8, 50 min enviando e 10 de pausa, em paralelo com o HD 2. Job `9103964d-c076-1f48-6a2f-f50336afb55a`.
