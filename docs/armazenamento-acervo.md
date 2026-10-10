# Acervo antigo — 8 TB

Padrão de acesso informado em 9 de outubro de 2026, em cima da arquitetura da [reunião de 24/08/2026](discovery-2026-08-24.md).

- Volume medido em 09/10/2026: **9 HDs, 6.971 GB** (cerca de 7,0 TB). Os 8 TB da reunião cobrem isso.
- Frequência: cerca de **uma vez por ano**. A hipótese de uma vez por mês foi descartada.
- Cada consulta: **no máximo 15 GB**, não os 8 TB.
- Espera aceita na reunião: até dois dias. O cliente ouve “no máximo dois dias”.

O ano corrente online (os 2 TB imediatos da reunião) fica para depois. Decisão de 09/10/2026: por enquanto só o arquivo.

## Camada

**S3 Glacier Deep Archive.**

É a classe que a reunião já descrevia, mesmo sem o nome completo: ~R$ 40/mês para 8 TB e recuperação de 12 a 48 horas. A AWS publica Deep Archive a US$ 0,00099 por GB/mês na região US East (cerca de US$ 1 por TB, ~US$ 8/mês para 8 TB) e recomenda essa classe para acesso inferior a uma vez por ano.

| Restore de 15 GB | Prazo típico | Tarifa publicada de leitura |
| --- | --- | --- |
| Standard | até 12 horas | US$ 0,02/GB → cerca de US$ 0,30 |
| Bulk | até 48 horas | US$ 0,0025/GB → alguns centavos |

Não existe restore expedito no Deep Archive. Para 15 GB, o Standard cabe no prazo de dois dias. O Bulk serve se a consulta for marcada com antecedência.

Restaurar os 8 TB inteiros é outro problema: a leitura Standard ficaria na casa de dezenas de dólares e o prazo deixa de ser o de um objeto pequeno. O desenho é restaurar só o pacote pedido.

Preço de tabela, US East, sem câmbio, sem imposto e sem a cópia temporária enquanto o arquivo restaurado fica online. Não é cotação.

Retenção mínima da classe: 180 dias. Apagar ou trocar de classe antes disso gera cobrança proporcional do período que falta. Consulta anual não esbarra nisso.

## Por que não as outras camadas

Acesso anual de 15 GB não paga armazenamento online.

- **Azure Cold** (e o equivalente instantâneo) deixa o arquivo abrir na hora e custa na ordem de dezenas de dólares por mês nos 8 TB. Serve para consulta mensal. Essa frequência saiu do cenário.
- **Backblaze B2** também é online, na ordem de US$ 6 por TB/mês (~US$ 48/mês nos 8 TB). Faz sentido se alguém for navegar o acervo. Não é o caso.
- **Azure Archive** fica no mesmo patamar do Deep Archive: cerca de US$ 1 a US$ 2 por TB/mês, offline, restore padrão de até 15 horas. A reunião já fechou AWS. Azure não muda o custo o bastante para trocar de provedor.

A prioridade alta da Azure (menos de 1 hora) vale para blob **abaixo de 10 GB**, com teto de **10 GiB por hora na conta**. Um zip de 15 GB não entra nessa promessa. No Deep Archive o caminho rápido simplesmente não existe: 15 GB voltam no Standard, em até 12 horas.

Mais HD, fita ou disco óptico não resolvem o que a Nanda descreveu: acervo em cerca de oito HDs, sem espaço e sem cópia fora do estúdio. A nuvem é essa cópia.

## Como empacotar

A unidade, onde o disco tem calendário, é a **sessão**. O resto sobe como está. Não se filtra conteúdo. O conjunto fechado é 9 HDs, 6.971 GB.

Os 15 GB são o quanto se restaura numa consulta, não o tamanho máximo do pacote. Sessão que passar disso continua sendo uma sessão. No HD NG 22 a média fica em cerca de 4 GB; maio estoura porque o CR2 está lá, e esse RAW sobe junto.

Cada objeto no Glacier carrega 40 KB de metadado cobrável. Empacotar a sessão num arquivo só evita restaurar milhares de objetos para abrir um trabalho.

## Conta anual, ordem de grandeza

| Item | Ordem |
| --- | --- |
| 7,0 TB medidos, 12 meses | ~US$ 83 |
| Uma sessão, cerca de 4 GB, Standard | ~US$ 0,08 |
| A mesma sessão em Bulk | ~US$ 0,01 |
| Ano corrente, 2 TB imediatos | fora, por enquanto. Era a maior parte do teto de ~R$ 500/mês falado na reunião |

## Fontes

- [S3 Glacier storage classes](https://aws.amazon.com/s3/storage-classes/glacier/) — Deep Archive a US$ 0,00099/GB-mês; restore de 12 h ou 48 h
- [Archive retrieval options](https://docs.aws.amazon.com/AmazonS3/latest/userguide/restoring-objects-retrieval-options.html)
- [Azure: rehydrate from Archive](https://learn.microsoft.com/en-us/azure/storage/blobs/archive-rehydrate-overview) — padrão até 15 h; prioridade alta para objeto abaixo de 10 GB; 10 GiB/hora por conta
