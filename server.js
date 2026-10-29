const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Porta que o Render usa para subir o site
const PORT = process.env.PORT || 3000;

// Chave da API do Datajud (pegamos das configurações do Render ou usamos padrão)
const DATAJUD_API_KEY = process.env.DATAJUD_API_KEY || "c3VwZXItc2VjcmV0LWtleQ==";

const BASE_URL = "https://api-publica.datajud.cnj.jus.br";

// Lista COMPLETA dos 85 tribunais do Datajud
const ENDPOINTS_TRIBUNAIS = [
    // Tribunais Superiores
    "api_publica_stj", "api_publica_tst", "api_publica_tse", "api_publica_stm",

    // Justiça Federal
    "api_publica_trf1", "api_publica_trf2", "api_publica_trf3", 
    "api_publica_trf4", "api_publica_trf5", "api_publica_trf6",

    // Justiça Estadual (TJs)
    "api_publica_tjac", "api_publica_tjal", "api_publica_tjam", "api_publica_tjap",
    "api_publica_tjba", "api_publica_tjce", "api_publica_tjdft", "api_publica_tjes",
    "api_publica_tjgo", "api_publica_tjma", "api_publica_tjmg", "api_publica_tjms",
    "api_publica_tjmt", "api_publica_tjpa", "api_publica_tjpb", "api_publica_tjpe",
    "api_publica_tjpi", "api_publica_tjpr", "api_publica_tjrj", "api_publica_tjrn",
    "api_publica_tjro", "api_publica_tjrr", "api_publica_tjrs", "api_publica_tjsc",
    "api_publica_tjse", "api_publica_tjsp", "api_publica_tjto",

    // Justiça do Trabalho (TRTs)
    "api_publica_trt1", "api_publica_trt2", "api_publica_trt3", "api_publica_trt4",
    "api_publica_trt5", "api_publica_trt6", "api_publica_trt7", "api_publica_trt8",
    "api_publica_trt9", "api_publica_trt10", "api_publica_trt11", "api_publica_trt12",
    "api_publica_trt13", "api_publica_trt14", "api_publica_trt15", "api_publica_trt16",
    "api_publica_trt17", "api_publica_trt18", "api_publica_trt19", "api_publica_trt20",
    "api_publica_trt21", "api_publica_trt22", "api_publica_trt23", "api_publica_trt24",

    // Justiça Eleitoral (TREs)
    "api_publica_tre-ac", "api_publica_tre-al", "api_publica_tre-am", "api_publica_tre-ap",
    "api_publica_tre-ba", "api_publica_tre-ce", "api_publica_tre-df", "api_publica_tre-es",
    "api_publica_tre-go", "api_publica_tre-ma", "api_publica_tre-mg", "api_publica_tre-ms",
    "api_publica_tre-mt", "api_publica_tre-pa", "api_publica_tre-pb", "api_publica_tre-pe",
    "api_publica_tre-pi", "api_publica_tre-pr", "api_publica_tre-rj", "api_publica_tre-rn",
    "api_publica_tre-ro", "api_publica_tre-rr", "api_publica_tre-rs", "api_publica_tre-sc",
    "api_publica_tre-se", "api_publica_tre-sp", "api_publica_tre-to",

    // Justiça Militar
    "api_publica_tjmmg", "api_publica_tjmrs", "api_publica_tjmmsp"
];

// Rota de teste
app.get('/', (req, res) => {
    res.json({ status: "Servidor JusSmart ativo!", total_tribunais: ENDPOINTS_TRIBUNAIS.length });
});

// Rota de busca no aplicativo
app.post('/consultar', async (req, res) => {
    const { numero_processo } = req.body;

    if (!numero_processo) {
        return res.status(400).json({ erro: "Informe o número do processo." });
    }

    const payload = {
        query: {
            match: {
                numeroProcesso: numero_processo.replace(/\D/g, '')
            }
        }
    };

    const headers = {
        'Authorization': `APIKey ${DATAJUD_API_KEY}`,
        'Content-Type': 'application/json'
    };

    const resultados = {};

    const buscas = ENDPOINTS_TRIBUNAIS.map(async (alias) => {
        try {
            const resp = await axios.post(`${BASE_URL}/${alias}/_search`, payload, { headers, timeout: 5000 });
            const hits = resp.data?.hits?.hits || [];
            resultados[alias] = { status: "sucesso", total_encontrado: hits.length, processos: hits };
        } catch (err) {
            resultados[alias] = { status: "sem_resultados_ou_erro", total_encontrado: 0, processos: [] };
        }
    });

    await Promise.all(buscas);
    return res.json(resultados);
});

app.listen(PORT, () => {
    console.log(`Servidor operando na porta ${PORT}`);
});
