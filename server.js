const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());

const PORT = process.env.PORT || 10000;
const DATAJUD_API_KEY = "cGFydGljaXBhbnRlOmRhdGFqdWRfcGFydGljaXBhbnRl";

app.get('/', (req, res) => {
  res.json({ status: "API JusSmart Universal Online", ok: true });
});

app.post('/api/buscar', async (req, res) => {
  const { tipo, valor } = req.body;

  if (!valor) {
    return res.status(400).json({ sucesso: false, mensagem: "Informe o valor para pesquisa." });
  }

  const valorLimpo = valor.replace(/\D/g, '');
  let queryElastic = {};

  if (tipo === 'numero') {
    queryElastic = {
      match: { "numeroProcesso": valorLimpo }
    };
  } else if (tipo === 'cpf') {
    queryElastic = {
      bool: {
        should: [
          { match: { "dadosBasicos.polo.parte.pessoa.numeroDocumentoPrincipal": valorLimpo } },
          { match: { "dadosBasicos.polo.parte.pessoa.numeroDocumento": valorLimpo } }
        ]
      }
    };
  } else {
    queryElastic = {
      match: {
        "dadosBasicos.polo.parte.pessoa.nome": {
          query: valor,
          operator: "and"
        }
      }
    };
  }

  try {
    const response = await axios.post(
      'https://api-publica.datajud.cnj.jus.br/api_publica_tjba/_search',
      { size: 50, query: queryElastic },
      {
        headers: {
          'Authorization': `APIKey ${DATAJUD_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 12000
      }
    );

    const hits = response.data.hits?.hits || [];
    const processos = hits.map(hit => {
      const src = hit._source || {};
      const numProc = src.numeroProcesso || valor;
      return {
        numero: numProc,
        tribunal: src.tribunal || "TJBA",
        classe: src.classe?.nome || "Procedimento Judicial",
        orgaoJulgador: src.orgaoJulgador?.nome || "Vara Cível",
        dataAjuizamento: src.dataAjuizamento ? new Date(src.dataAjuizamento).toLocaleDateString('pt-BR') : "Não informada",
        linkConsulta: `https://pje.tjba.jus.br/pje/ConsultaPublica/listView.seam?numeroProcesso=${numProc}`
      };
    });

    res.json({ sucesso: true, total: processos.length, processos });

  } catch (error) {
    res.status(500).json({ sucesso: false, erro: error.message, processos: [] });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor JusSmart rodando na porta ${PORT}`);
});
