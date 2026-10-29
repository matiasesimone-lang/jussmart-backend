const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const API_KEY = "APIKey c3VwZXJ1c2VyaW5mcmE6N2M1YjI4NjgtM2M1Yi00OWU1LTk1OWEtN2IzYjU0YWIyYTM4";

// Teste focado especificamente no TJBA para diagnóstico
app.post('/consultar', async (req, res) => {
  const { tipo, termo } = req.body;
  const valorBusca = termo || "";
  const numeroLimpo = valorBusca.replace(/\D/g, '');

  let queryPayload = {
    query: {
      match: {
        "numeroProcesso": numeroLimpo
      }
    }
  };

  if (tipo === 'cpf') {
    queryPayload = {
      query: {
        bool: {
          should: [
            { match: { "qualificacaoEnvolvido.numeroDocumento": numeroLimpo } },
            { match: { "presents.cpfCnpj": numeroLimpo } }
          ]
        }
      }
    };
  }

  try {
    const url = "https://api-publica.datajud.cnj.jus.br/API_PUBLICA_TJBA/_search";
    console.log("Enviando requisição ao TJBA com o payload:", JSON.stringify(queryPayload));

    const response = await axios.post(url, queryPayload, {
      headers: {
        'Authorization': API_KEY,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    console.log("Resposta bruta do Datajud TJBA:", JSON.stringify(response.data));

    const hits = response.data?.hits?.hits || [];
    const total = response.data?.hits?.total?.value || 0;

    res.json({
      "API_PUBLICA_TJBA": {
        status: "sucesso",
        total_encontrado: total,
        detalhes_resposta: response.data,
        processos: hits.map(h => ({
          numeroProcesso: h._source?.numeroProcesso,
          classe: h._source?.classe?.nome,
          status: h._source?.baixa ? "Inativo / Arquivado" : "Ativo",
          ultimaMovimentacao: h._source?.movimentos?.[0]?.nome || "Sem movimentação"
        }))
      }
    });

  } catch (error) {
    console.error("Erro na chamada ao Datajud:", error.response ? error.response.data : error.message);
    res.status(500).json({
      erro: "Falha na comunicação com o Datajud",
      mensagem_detalhada: error.response ? error.response.data : error.message,
      codigo_status: error.response ? error.response.status : 500
    });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor de Diagnóstico rodando na porta ${PORT}`);
});
