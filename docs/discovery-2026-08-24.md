# Discovery — Studio Nanda Gil

**Cliente:** Studio Nanda Gil (nome informado pelo Guilherme; a transcrição não registra)  
**Reunião:** [Plataforma de fotos — armazenamento em nuvem, fluxo de trabalho e automação](https://notes.granola.ai/d/26a8c1e2-dbbb-4aa6-9a1e-c6c4a98cbba6)  
**Data:** 24 de agosto de 2026, 17:39 (GMT-3)  
**Quem gravou:** Guilherme Resende (Aurion)  
**Tipo:** discovery e alinhamento operacional

Quem fala o processo é a operação do Studio Nanda Gil. A Aurion entra em armazenamento, desenho da nuvem e automação de avisos e dúvidas recorrentes.

## Problema

O acervo vive em HDs físicos, sem nuvem estruturada. A equipe está sem espaço e pedindo compra de mais disco. Há risco de perda e pressão para resolver antes do Natal de 2026.

A plataforma de entrega é outra camada. Ela guarda o álbum do cliente enquanto o trabalho está aberto. Não é o arquivo de longo prazo. Cliente fica meses na plataforma (exemplo: da gestação até o bebê com seis meses) e só sai depois que o álbum fecha. Isso aperta o espaço da plataforma o tempo todo.

## Fluxo operacional

1. Sessão fotografada. O estúdio salva no computador e numa segunda cópia local. A nuvem entra como essa segunda cópia, com visualização e download simples.
2. Edição. De 600 a 1.200 cliques por cliente, a entrega fica em cerca de 200 fotos. Na call, a operação disse que subiria as editadas e que a câmera nova grava JPEG, porque o JPEG cobre a entrega e a ampliação. A regra do acervo, fechada em 09/10/2026, é outra: salvar o HD inteiro, por sessão, inclusive RAW.
3. Cliente recebe um link do álbum. Exemplo citado: Renata, três sessões — gestante, mês 1 e mês 6.
4. Pacote é fixo: **30 fotos** ou **todas**.
5. Duas ações distintas no mesmo álbum:
   - **Seleção** — fotos para download.
   - **Favorito (estrelinha)** — fotos que entram no álbum impresso.
6. Com várias sessões, os favoritos se dividem entre elas. Exemplo falado: álbum de cerca de 30 páginas, 10 fotos de cada uma das três sessões.
7. Com os favoritos, a equipe baixa, a Ana manda o álbum para aprovação e depois para produção.
8. Montagem de layout é rápida. O gargalo é a **edição**.
9. Álbum finalizado: o cliente sai da plataforma.

## O que a plataforma precisa mostrar

A plataforma atual não entrega o que a operação precisa. A nova precisa de fluxo visual, no modelo kanban: status do cliente, responsável e etapa.

Etapas citadas:

- aguardando edição
- aguardando seleção

Cada pessoa da equipe enxerga o que é dela, sem depender de memória para cobrar o cliente.

A plataforma atual não avisa que o link vai expirar. O estúdio quer aviso automático, de preferência por WhatsApp. Exemplos falados: “daqui a 7 dias você precisa baixar” e aviso se passar cerca de 30 dias sem download. Se a plataforma nova não tiver WhatsApp nativo, a Aurion segue com aviso próprio.

Nomes de plataforma na transcrição estão ruins de áudio. “CNMZ” foi dito e em seguida desmentido. Não usar esse nome como fato.

## Chatbot

Dúvidas que já se repetem:

- como baixar
- como abrir o arquivo (WinRAR)
- como entrar no link

O estúdio já tem mensagens prontas para esses casos. A Ana levanta as perguntas básicas mais frequentes e manda o resumo para a Aurion montar o bot. Dá para cruzar com as conversas de WhatsApp.

Restrição explícita: a automação fica no corriqueiro. O atendimento humano continua. A saída do bot é **só para a Ana**.

## Armazenamento

| Item | Número falado |
| --- | --- |
| Clientes por ano | ~180 |
| Fotos entregues por cliente | ~200 JPEG editados |
| Volume anual a guardar | ~36.000 imagens |
| Retenção | ano corrente + no máximo 2 anos anteriores |
| HDs físicos | cerca de 8 (a fala oscila; tamanho real em aberto) |
| O que a call falou em subir | fotos editadas (~200), não os 600–1.200 cliques; câmera nova em JPEG |

Acesso:

- **Ano corrente:** instantâneo. É o que a operação usa no dia a dia.
- **Dois anos anteriores:** raro. Pode esperar. Glacier cabe aqui. Recuperação falada: 12 a 48 horas. Combinado com o cliente: “no máximo dois dias”.

O acesso do acervo foi fechado depois: 8 TB, no máximo 15 GB por consulta, cerca de uma vez por ano. A classe é S3 Glacier Deep Archive. Detalhe em [Acervo antigo — 8 TB](armazenamento-acervo.md).

Arquitetura combinada na call, ainda como desenho, não como fechamento:

| Camada | Volume falado | Custo falado |
| --- | --- | --- |
| S3 Glacier (acervo antigo) | 8 TB | ~R$ 40/mês |
| Instantâneo (ano corrente) | 2 TB | 8 TB instantâneo foi chutado em ~R$ 340/mês; 2 TB é a fatia proporcional |
| Teto da estimativa | — | ~R$ 500/mês, com folga, se não houver muito movimento |

Comparativo citado: Google AI Plus, 2 TB, R$ 96/mês, pacote com outros serviços, sem opção clara de comprar só espaço. Amazon foi a escolha da conversa: mais barato e mais confiável para esse volume.

O dimensionamento final depende de medir os HDs e o peso real do JPEG. Sem isso, 8 TB + 2 TB é hipótese de trabalho.

## Decisões da reunião

- Trocar a plataforma de entrega por uma com kanban de status, responsável e etapa.
- Avisar o cliente, de preferência por WhatsApp, sobre prazo de seleção, favoritos e download.
- Chatbot só para dúvida repetida, com saída humana exclusiva para a Ana.
- Nuvem na AWS: Glacier para o antigo, instantâneo para o ano corrente.
- Correção de 09/10/2026: salva tudo o que está nos HDs, organizado por sessão. RAW, JPEG, vídeo, árvore de clientes, pessoal e presets entram. A call tinha falado em subir só as editadas; isso não vale para a migração.
- Correção de 09/10/2026: os 2 TB instantâneos do ano corrente ficam para depois. Por enquanto só o arquivo.
- Resolver o armazenamento antes do Natal de 2026.

## Próximos passos saídos da call

| O quê | Quem |
| --- | --- |
| Desenhar a arquitetura (8 TB Glacier + 2 TB instantâneo) e mandar o desenho | Aurion (Guilherme se comprometeu a desenhar) |
| Confirmar capacidade real dos HDs e o tamanho dos arquivos | Guilherme, com o material do estúdio |
| Listar as perguntas frequentes para a base do bot | Ana |
| Ver se a plataforma nova tem WhatsApp nativo | Aurion. Se não tiver, aviso próprio |

## Em aberto

- Nome da plataforma atual e da nova.
- Tamanho real dos HDs e peso médio do JPEG.
- Volume mensal de mensagens de WhatsApp, para fechar custo do aviso automático.
- Se “Mari” (citada na transcrição junto da Ana) entra no levantamento de dúvidas ou se o canal é só a Ana. A saída humana ficou explícita: só a Ana.
