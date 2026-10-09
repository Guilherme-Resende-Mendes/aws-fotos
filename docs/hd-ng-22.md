# HD NG 22 — estrutura real

Disco lido em 9 de outubro de 2026. Volume `D:`, rótulo **HD NG 22**, Seagate, NTFS, 931 GB, 125 GB livres. O acervo está em `D:\2022`: **175.025 arquivos, 757 GB**. O resto da raiz é instalador e ícone do Seagate.

Este HD é o ano de 2022. Os outros discos do estúdio ainda não foram lidos. O padrão abaixo é o que a migração deve esperar, com variação de um disco para outro.

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

## De onde saiu “não salvar RAW”

Da transcrição de 24/08/2026, na fala de quem opera o estúdio: subiria para a nuvem as fotos editadas (cerca de 200 por cliente, não os 600 a 1.200 cliques) e, dali para a frente, a câmera passou a gravar JPEG porque o JPEG bastava para a entrega. Eu tratei isso como regra do acervo antigo. Em 09/10/2026 o Guilherme corrigiu: salva por sessão, o RAW entra, e entra tudo o que está nos HDs.
