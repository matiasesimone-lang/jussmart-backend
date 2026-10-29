const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Chave pública fornecida pelo Datajud CNJ
const API_KEY = "APIKey c3VwZXJ1c2VyaW5mcmE6N2M1YjI4NjgtM2M1Yi00OWU1LTk1OWEtN2IzYjU0YWIyYTM4";

// Lista de tribunais para consulta unificada no Datajud
const TRIBUNAIS = [
  "API_PUBLICA_TJBA", "API_PUBLICA_TJPE", "API_PUBLICA_TJCE", "API_PUBLICA_TJAL",
  "API_PUBLICA_TJMA", "API_PUBLICA_TJPB", "API_PUBLICA_TJPI", "API_PUBLICA_TJRN",
  "API_PUBLICA_TJSE", "API_PUBLICA_TJSP", "API_PUBLICA_TJRJ", "API_PUBLICA_TJMG",
  "API_PUBLICA_TJRS", "API_PUBLICA_TJPR", "API_PUBLICA_TJSC", "API_PUBLICA_TJDF",
  "API_PUBLICA_TJGO", "API_PUBLICA_TJMT", "API_PUBLICA_MS", "API_PUBLICA_TJAM",
  "API_PUBLICA_TJPA", "API_PUBLICA_TJAP", "API_PUBLICA_TJAC", "API_PUBLICA_TJRO",
  "API_PUBLICA_TJRR", "API_PUBLICA_TO", "API_PUBLICA_TRF1", "API_PUBLICA_TRF2",
  "API_PUBLICA_TRF3", "API_PUBLICA_TRF4", "API_PUBLICA_TRF5", "API_PUBLICA_TRF6"
];

app.get('/', (req, res) => {
  res.json({ status: "Servidor JusSmart ativo!", total_tribunais: TRIBUNAIS.length });
});

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
            { match: { "presents.cpfCnpj": cpfFormatado } },
            { match_phrase: { "presents.nome": valorBusca } }
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
    // Número do processo limpo (apenas dígitos)
    const numeroApenasNumeros = valorBusca.replace(/\D/g, '');
    queryPayload = {
      query: {
        match: {
          "numeroProcesso": numeroApenasNumeros
        }
      }
    };
  }

  // Consulta simultânea nos tribunais
  const promessas = TRIBUNAIS.map(async (tribunal) => {
    const url = `https://api-publica.datajud.cnj.jus.br/${tribunal}/_search`;
    try {
      const response = await axios.post(url, queryPayload, {
        headers: {
          'Authorization': API_KEY,
          'Content-Type': 'application/json'
        },
        timeout: 12000
      });

      const hits = response.data?.hits?.hits || [];
      const totalHits = response.data?.hits?.total?.value || 0;

      const processosDetalhados = hits.map(hit => {
        const source = hit._source || {};
        const movimentos = source.movimentos || [];
        
        // Ordena movimentos por data mais recente
        movimentos.sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora));
        const ultimaMov = movimentos[0] || {};
        const baixado = source.baixa || false;

        // Identifica se há audiência marcada nas movimentações
        const movAudiencia = movimentos.find(m => 
          (m.nome || '').toLowerCase().includes('audiência') || 
          (m.nome || '').toLowerCase().includes('audiencia')
        );

        return {
          numeroProcesso: source.numeroProcesso || "Sem número registrado",
          classe: source.classe?.nome || "Não informada",
          tribunal: source.tribunal || tribunal.replace("API_PUBLICA_", ""),
          status: baixado ? "Inativo / Arquivado" : "Ativo",
          ultimaMovimentacao: {
            nome: ultimaMov.nome || "Sem movimentação recente registrada",
            data: ultimaMov.dataHora ? new Date(ultimaMov.dataHora).toLocaleDateString('pt-BR') : "N/A"
          },
          audiencia: movAudiencia ? {
            evento: movAudiencia.nome,
            data: movAudiencia.dataHora ? new Date(movAudiencia.dataHora).toLocaleDateString('pt-BR') : "Data não especificada"
          } : null,
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
