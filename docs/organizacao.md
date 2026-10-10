# Como organizar os arquivos

Um zip por trabalho. O caminho do zip repete o caminho do disco. Um índice ao lado encontra a cliente.

A pasta do trabalho é a sessão, quando o disco tem calendário, ou a pasta do ensaio, quando o ano ou o evento já está quebrado assim. A média dessa pasta é cerca de 4 GB. Abrir a cliente é restaurar esse zip, não o mês e não o disco.

Não se cria uma árvore nova por cliente. O mesmo tema aparece em discos diferentes com tamanho diferente. Natal 20, por exemplo, tem 17 pastas num HD e 35 em outro. Fundir sem conferir arquivo a arquivo ou perde foto ou sobe a mesma pasta duas vezes sem saber.

## Onde o zip corta

| Disco | O zip é |
| --- | --- |
| HD NG 22 | cada sessão dentro do mês, e cada sessão dentro de `2022 CLIENTES` |
| Seagate, 2018 a 2021 | cada pasta de trabalho dentro do ano |
| Toshiba | cada trabalho dentro de `NATAL 20` … `NATAL 25` |
| ADATA | cada pasta em `clientes 2020`, em `2021` e em `NATAL 20` |
| HD NG 21 | cada trabalho dentro do Dia das Mães ou do Natal 20 |
| HD 2024 e 2025 NG | cada sessão dentro do mês |
| One Touch | cada sessão dentro do mês de 2023, cada trabalho de Natal, cada pasta de 2026 |
| Samsung | cada pasta de trabalho, inclusive o que está solto na raiz e em `nanda NAO APAGAR` |

Mês não vira zip. Em 2023, 2024 e 2025 o mês passa de 40 GB. Evento também não: Natal 20 no NG 21 tem 86 GB.

Pasta que não tem trabalho dentro dela sobe inteira. Dia das Mães 22 é um caso: uma pasta só, 22 GB.

## O caminho

```
hd-ng-22/2022/05 - MAIO/sessao.zip
hd-ng-22/2022/2022 CLIENTES/cliente/sessao.zip
toshiba-ext/HOMESTUDIO/NATAL 20/trabalho.zip
seagate/2020/trabalho.zip
```

O nome da pasta não se traduz e não se junta. `2022 CLIENTES` e o calendário de 2022 sobem os dois.

## O índice

Uma linha por zip:

| Campo | Uso |
| --- | --- |
| disco | de qual HD veio |
| caminho | o zip a restaurar |
| nome | a pasta, do jeito que está no HD. É a busca da cliente |
| bytes | tamanho |
| sha256 | confere a cópia antes de soltar o HD |

Pedir uma cliente é filtrar a coluna nome e restaurar os zips dessa linha, um por vez. Três sessões da mesma pessoa são três zips.

## O que fica de fora do zip

Instalador do fabricante (`Start_Here`, `Warranty`, `Autorun`) e lixo de sistema (`.Spotlight-V100`, `.Trashes`). O resto entra: RAW, JPEG, vídeo, PSD, pessoal e presets.
