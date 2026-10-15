const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

const PORT = process.env.PORT || 10000;
const DATAJUD_API_KEY = "cGFydGljaXBhbnRlOmRhdGFqdWRfcGFydGljaXBhbnRl";

// Lista de endpoints dos Tribunais Estaduais, Federais e Trabalhistas
const TRIBUNAIS_ALVO = [
  { sigla: "TJBA", index: "api_publica_tjba", esfera: "Estadual (BA)" },
  { sigla: "TRF1", index: "api_publica_trf1", esfera: "Federal (BA/DF/Região)" },
  { sigla: "TRF5", index: "api_publica_trf5", esfera: "Federal (PE/AL/Região)" },
  { sigla: "TRT5", index: "api_publica_trt5", esfera: "Trabalhista (BA)" },
  { sigla: "TJPE", index: "api_publica_tjpe", esfera: "Estadual (PE)" },
  { sigla: "TJSP", index: "api_publica_tjsp", esfera: "Estadual (SP)" },
  { sigla: "TJRJ", index: "api_publica_tjrj", esfera: "Estadual (RJ)" }
];

app.get('/', (req, res) => {
  res.json({ status: "API JusSmart Multi-Tribunais Online", timestamp: new Date() });
});

app.post('/api/buscar', async (req, res) => {
  const { tipo, valor } = req.body;

  if (!valor) {
    return res.status(400).json({ sucesso: false, mensagem: "Informe o valor para busca." });
  }

  const valorLimpo = valor.replace(/\D/g, '');

  // Estruturação da consulta para a API do DataJud
  let queryElastic = {};
  if (tipo === 'numero') {
    queryElastic = { match: { "numeroProcesso": valorLimpo } };
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
    // Busca por nome flexível (todas as palavras presentes)
    queryElastic = {
      match: {
        "dadosBasicos.polo.parte.pessoa.nome": {
          query: valor,
          operator: "and"
        }
      }
    };
  }

  // Executa as requisições em paralelo em todos os tribunais cadastrados
  const buscasParalelas = TRIBUNAIS_ALVO.map(trib => {
    return axios.post(
      `https://api-publica.datajud.cnj.jus.br/${trib.index}/_search`,
      { size: 25, query: queryElastic },
      {
        headers: {
          'Authorization': `APIKey ${DATAJUD_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      }
    ).then(resData => ({ tribunalInfo: trib, hits: resData.data.hits?.hits || [] }))
     .catch(() => ({ tribunalInfo: trib, hits: [] }));
  });

  try {
    const resultadosTribunais = await Promise.all(buscasParalelas);
    let todosProcessos = [];

    resultadosTribunais.forEach(item => {
      const { tribunalInfo, hits } = item;
      hits.forEach(hit => {
        const src = hit._source || {};
        const numProc = src.numeroProcesso;
        if (numProc) {
          todosProcessos.push({
            numero: numProc,
            tribunal: src.tribunal || tribunalInfo.sigla,
            esfera: tribunalInfo.esfera,
            status: src.classe?.nome || "Procedimento Judicial",
            orgaoJulgador: src.orgaoJulgador?.nome || "Vara Judicial",
            dataAjuizamento: src.dataAjuizamento ? new Date(src.dataAjuizamento).toLocaleDateString('pt-BR') : "Não informada",
            linkConsulta: `https://pje.tjba.jus.br/pje/ConsultaPublica/listView.seam?numeroProcesso=${numProc}`
          });
        }
      });
    });

    res.json({
      sucesso: true,
      totalEncontrados: todosProcessos.length,
      processos: todosProcessos
    });

  } catch (error) {
    res.status(500).json({ sucesso: false, erro: "Falha na varredura multi-tribunais: " + error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor JusSmart Multi-Tribunais rodando na porta ${PORT}`);
});
