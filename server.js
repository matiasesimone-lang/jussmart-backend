const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

const PORT = process.env.PORT || 10000;
const DATAJUD_API_KEY = "cGFydGljaXBhbnRlOmRhdGFqdWRfcGFydGljaXBhbnRl";

// Mapeamento dos principais tribunais pelo código CNJ (J.TR)
const TRIBUNAIS_CNJ = {
  "8.05": { sigla: "TJBA", index: "api_publica_tjba" },
  "8.26": { sigla: "TJSP", index: "api_publica_tjsp" },
  "8.19": { sigla: "TJRJ", index: "api_publica_tjrj" },
  "8.13": { sigla: "TJMG", index: "api_publica_tjmg" },
  "8.17": { sigla: "TJPE", index: "api_publica_tjpe" },
  "4.05": { sigla: "TRF5", index: "api_publica_trf5" },
  "5.05": { sigla: "TRT5", index: "api_publica_trt5" }
};

app.get('/', (req, res) => {
  res.json({ status: "API JusSmart Universal Online", timestamp: new Date() });
});

app.post('/api/buscar', async (req, res) => {
  const { tipo, valor } = req.body;

  if (!valor) {
    return res.status(400).json({ sucesso: false, mensagem: "Informe o valor para busca." });
  }

  const valorLimpo = valor.replace(/\D/g, '');
  let targetIndex = "api_publica_tjba"; // Padrão TJBA

  // Identificação automática do tribunal se for número CNJ de 20 dígitos
  if (tipo === 'numero' && valorLimpo.length >= 16) {
    const subStrJTR = `${valorLimpo.substring(13, 14)}.${valorLimpo.substring(14, 16)}`;
    if (TRIBUNAIS_CNJ[subStrJTR]) {
      targetIndex = TRIBUNAIS_CNJ[subStrJTR].index;
    }
  }

  try {
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
      // Busca por Nome com operador flexível (localiza as palavras do nome em qualquer ordem)
      queryElastic = {
        match: {
          "dadosBasicos.polo.parte.pessoa.nome": {
            query: valor,
            operator: "and"
          }
        }
      };
    }

    const response = await axios.post(
      `https://api-publica.datajud.cnj.jus.br/${targetIndex}/_search`,
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
      const siglaTrib = src.tribunal || targetIndex.replace('api_publica_', '').toUpperCase();

      return {
        numero: numProc,
        tribunal: siglaTrib,
        status: src.classe?.nome || "Procedimento Judicial",
        orgaoJulgador: src.orgaoJulgador?.nome || "Vara Judicial",
        dataAjuizamento: src.dataAjuizamento ? new Date(src.dataAjuizamento).toLocaleDateString('pt-BR') : "Não informada",
        linkConsulta: `https://pje.tjba.jus.br/pje/ConsultaPublica/listView.seam?numeroProcesso=${numProc}`
      };
    });

    res.json({ sucesso: true, total: processos.length, processos });

  } catch (error) {
    res.status(500).json({ sucesso: false, erro: "Falha na consulta ao DataJud: " + error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor JusSmart Universal rodando na porta ${PORT}`);
});
