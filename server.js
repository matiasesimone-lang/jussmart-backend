const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

const PORT = process.env.PORT || 10000;
const DATAJUD_API_KEY = "cGFydGljaXBhbnRlOmRhdGFqdWRfcGFydGljaXBhbnRl";

app.get('/', (req, res) => {
  res.json({ status: "API JusSmart Online", timestamp: new Date() });
});

app.post('/api/buscar', async (req, res) => {
  const { tipo, valor } = req.body;

  if (!valor) {
    return res.status(400).json({ sucesso: false, mensagem: "Informe o valor para busca." });
  }

  const valorLimpo = valor.replace(/\D/g, '');

  try {
    let mustQueries = [];

    if (tipo === 'numero') {
      mustQueries.push({ match: { "numeroProcesso": valorLimpo } });
    } else if (tipo === 'cpf') {
      mustQueries.push({
        bool: {
          should: [
            { match: { "dadosBasicos.polo.parte.pessoa.numeroDocumento": valorLimpo } },
            { wildcard: { "dadosBasicos.polo.parte.pessoa.numeroDocumento": `*${valorLimpo}*` } }
          ]
        }
      });
    } else {
      mustQueries.push({ match: { "dadosBasicos.polo.parte.pessoa.nome": valor } });
    }

    const bodyQuery = {
      size: 100,
      query: {
        bool: {
          must: mustQueries
        }
      }
    };

    const response = await axios.post(
      'https://api-publica.datajud.cnj.jus.br/api_publica_tjba/_search',
      bodyQuery,
      {
        headers: {
          'Authorization': `APIKey ${DATAJUD_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 15000
      }
    );

    const hits = response.data.hits?.hits || [];
    const processos = hits.map(hit => {
      const src = hit._source || {};
      const numProc = src.numeroProcesso || valor;
      return {
        numero: numProc,
        tribunal: src.tribunal || "TJBA",
        status: src.classe?.nome || "Procedimento Comum Cível",
        orgaoJulgador: src.orgaoJulgador?.nome || "Vara Cível",
        linkConsulta: `https://pje.tjba.jus.br/pje/ConsultaPublica/listView.seam?numeroProcesso=${numProc}`
      };
    });

    res.json({ sucesso: true, processos });

  } catch (error) {
    res.status(500).json({ sucesso: false, erro: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor JusSmart rodando na porta ${PORT}`);
});
