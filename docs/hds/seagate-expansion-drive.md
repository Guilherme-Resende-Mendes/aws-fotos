# HD 2 — Seagate Expansion Drive

Disco **2** na ordem em que o Guilherme ligou. Inventário em 2026-10-09 10:19. Volume `D:`, rótulo **Seagate Expansion Drive**, série `5E1DACF2`. O disco 1 é o [HD NG 22](../hd-ng-22.md), ano 2022.

|                   |           |
| ----------------- | --------- |
| Capacidade        | 1863 GB   |
| Livre             | 357 GB    |
| Arquivos lidos    | 484.181   |
| Volume lido       | 1490,5 GB |
| Falhas de leitura | 0         |

## Pastas na raiz

| Pasta           | Arquivos | GB     |
| --------------- | -------- | ------ |
| 2020            | 218.843  | 614,77 |
| 2021            | 125.670  | 562,98 |
| HD DO BKP NANDA | 123.217  | 274,82 |
| 2019            | 15.110   | 35,94  |
| 2018            | 1.278    | 1,65   |
| Pessoal Nanda   | 23       | 0,30   |

O restante da raiz é instalador do Seagate.

## Extensoes

| Extensao          | Arquivos | GB       |
| ----------------- | -------- | -------- |
| `.jpg`            | 473.355  | 1.294,20 |
| `.mov`            | 4.406    | 160,46   |
| `.psd`            | 239      | 12,08    |
| `.mp4`            | 34       | 9,70     |
| extensao ilegivel | 4.154    | 13,35    |
| `.jpeg`           | 168      | 0,14     |
| `.docx`           | 205      | 0,10     |
| `.cr2`            | 8        | 0,10     |
| `.pdf`            | 141      | 0,07     |
| `.mbf`            | 3        | 0,07     |

## Como o disco está organizado

Não é o corte `mês / sessão` do HD NG 22. Na raiz estão os anos **2018, 2019, 2020 e 2021**, mais `HD DO BKP NANDA` (275 GB, pastas `NANDA HD NOVO` e `Resultado de Digitalização Profunda`) e `Pessoal Nanda` (0,3 GB).

Dentro do ano, a pasta numerada (`01 - …`) é o trabalho, não o mês. Em 2020 e 2021 a maior parte das pastas nem usa número.

| Ano  | Pastas | Numeradas `NN -` | Com outro nome |
| ---- | ------ | ---------------- | -------------- |
| 2018 | 1      | 0                | 1              |
| 2019 | 14     | 14               | 0              |
| 2020 | 117    | 54               | 63             |
| 2021 | 208    | 16               | 192            |

O disco sobe inteiro.

## Envio para o Azure

Começou em 09/10/2026 às 23:18, para `acervo/seagate-expansion-drive`, camada Archive. Script: [upload-seagate.ps1](../../scripts/upload-seagate.ps1), retomado em ciclos por [upload-ciclos.ps1](../../scripts/upload-ciclos.ps1) (job `7b782459-0dd8-fe4b-4197-c069ff78a238`).

**O disco trava sob carga.** Com concorrência 32 caiu do USB em 45 s. Com 16 caiu três vezes entre 02:24 e 11:43 de 10/10, uma delas sem voltar sozinho, só reconectando. O CrystalDiskInfo (10/10 11:12) mostra a superfície saudável: 0 setores realocados, pendentes ou incorrigíveis, 0 erro de CRC, 4 *command timeouts*, temperatura máxima de 52 °C. Modelo ST2000LM007, 2,5", 5.400 rpm, alimentado pelo USB (UASP). A queda de 11:43 aconteceu com o disco frio, então o suspeito é a ligação USB, não o calor.

Desde a reconexão de 10/10 18:42 roda com concorrência 12, 50 min enviando e 10 de pausa, sem queda. Se cair, o script espera o disco voltar, esfria 20 min e baixa a concorrência em 4.

**Nomes inválidos.** Os arquivos recuperados em `Resultado de Digitalização Profunda\…\Other lost files` têm o caractere de controle U+0081 no nome, que o Azure recusa. Sobem depois do envio principal por [upload-nomes-invalidos.ps1](../../scripts/upload-nomes-invalidos.ps1), com o caractere trocado por `{U+0081}`; o HD não é alterado e a troca fica em `manifests/seagate-expansion-drive-nomes-trocados.csv`.
