const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const API_KEY = "c3VwZXJ1c2VyaW5mcmE6N2M1YjI4NjgtM2M1Yi00OWU1LTk1OWEtN2IzYjU0YWIyYTM4";

// Lista de tribunais para consulta unificada no Datajud
const TRIBUNAIS = [
  "API_PUBLICA_TJBA", "API_PUBLICA_TJPE", "API_PUBLICA_TJCE", "API_PUBLICA_TJAL",
  "API_PUBLICA_TJMA", "API_PUBLICA_TJPB", "API_PUBLICA_TJPI", "API_PUBLICA_TJRN",
  "API_PUBLICA_TJSE", "API_PUBLICA_TJSP", "API_PUBLICA_TJRJ", "API_PUBLICA_TJMG",
  "API_PUBLICA_TJRS", "API_PUBLICA_TJPR", "API_PUBLICA_TJSC", "API_PUBLICA_TJDF",
  "API_PUBLICA_TJGO", "API_PUBLICA_TJMT", "API_PUBLICA_MS", "API_PUBLICA_TJAM",
  "API_PUBLICA_TJPA", "API_PUBLICA_TJAP", "API_PUBLICA_TJAC", "API_PUBLICA_TJRO",
  "API_PUBLICA_TJRR", "API_PUBLICA_TO", "API_PUBLICA_TRF1", "API_PUBLICA_TRF2",
  "API_PUBLICA_TRF3", "API_PUBLICA_TRF4", "API_PUBLICA_TRF5", "API_PUBLICA_TRF6",
  "API_PUBLICA_TST", "API_PUBLICA_TRT1", "API_PUBLICA_TRT2", "API_PUBLICA_TRT3",
  "API_PUBLICA_TRT4", "API_PUBLICA_TRT5", "API_PUBLICA_TRT6", "API_PUBLICA_TRT13",
  "API_PUBLICA_TRT19", "API_PUBLICA_TRE-BA", "API_PUBLICA_TRE-PE", "API_PUBLICA_TRE-DF"
];

// Rota de verificação de status
app.get('/', (req, res) => {
  res.json({ status: "Servidor JusSmart ativo!", total_tribunais: TRIBUNAIS.length });
});

// Rota unificada de consulta aos tribunais
app.post('/consultar', async (req, res) => {
  const { tipo, termo, numero_processo } = req.body;
  const valorBusca = termo || numero_processo;

  if (!valorBusca) {
    return res.status(400).json({ erro: "Termo de busca não fornecido." });
  }

  let resultados = {};
  let queryPayload = {};

  if (tipo === 'cpf') {
    const apenasNumeros = valorBusca.replace(/\D/g, '');
    let cpfFormatado = apenasNumeros;
    if (apenasNumeros.length === 11) {
      cpfFormatado = apenasNumeros.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");
    } else if (apenasNumeros.length === 14) {
      cpfFormatado = apenasNumeros.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
    }

    queryPayload = {
      query: {
        bool: {
          should: [
            { match: { "qualificacaoEnvolvido.numeroDocumento": apenasNumeros } },
            { match: { "qualificacaoEnvolvido.numeroDocumento": cpfFormatado } },
            { match: { "presents.cpfCnpj": apenasNumeros } },
            { match: { "presents.cpfCnpj": cpfFormatado } }
          ]
        }
      }
    };
  } else if (tipo === 'nome') {
    queryPayload = {
      query: {
        bool: {
          should: [
            { match_phrase: { "presents.nome": valorBusca } },
            { match_phrase: { "qualificacaoEnvolvido.nome": valorBusca } },
            { match_phrase: { "nome": valorBusca } }
          ]
        }
      }
    };
  } else {
    const numeroLimpo = valorBusca.replace(/\D/g, '');
    queryPayload = {
      query: {
        match: {
          "numeroProcesso": numeroLimpo
        }
      }
    };
  }

  // Executa as consultas em lote para todos os tribunais
  const promessas = TRIBUNAIS.map(async (tribunal) => {
    const url = `https://api-publica.datajud.cnj.jus.br/${tribunal}/_search`;
    try {
      const response = await axios.post(url, queryPayload, {
        headers: {
          'Authorization': `APIKey ${API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 9000
      });

      const hits = response.data?.hits?.hits || [];
      const totalHits = response.data?.hits?.total?.value || 0;

      const processosDetalhados = hits.map(hit => {
        const source = hit._source || {};
        const movimentos = source.movimentos || [];
        
        movimentos.sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora));
        const ultimaMov = movimentos[0] || {};

        const baixado = source.baixa || false;
        const statusProcesso = baixado ? "Inativo / Arquivado" : "Ativo";

        return {
          numeroProcesso: source.numeroProcesso,
          classe: source.classe?.nome || "Não informada",
          tribunal: source.tribunal || tribunal.replace("API_PUBLICA_", ""),
          status: statusProcesso,
          ultimaMovimentacao: {
            nome: ultimaMov.nome || "Sem movimentação recente registrada",
            data: ultimaMov.dataHora ? new Date(ultimaMov.dataHora).toLocaleDateString('pt-BR') : "N/A"
          },
          previsaoProximoAndamento: baixado 
            ? "Processo arquivado. Sem previsão de movimentações automáticas." 
            : "Estimativa de próxima movimentação em até 30 a 60 dias úteis."
        };
      });

      resultados[tribunal] = {
        status: totalHits > 0 ? "sucesso" : "sem_resultados",
        total_encontrado: totalHits,
        processos: processosDetalhados
      };
    } catch (error) {
      resultados[tribunal] = {
        status: "sem_resultados_ou_erro",
        total_encontrado: 0,
        processos: []
      };
    }
  });

  await Promise.all(promessas);
  res.json(resultados);
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});
