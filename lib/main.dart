import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const JusSmartApp());
}

class JusSmartApp extends StatelessWidget {
  const JusSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JusSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488),
        ),
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final TextEditingController _controladorBusca = TextEditingController();
  String _tipoConsulta = 'numero'; // 'numero', 'cpf', 'nome'
  bool _carregando = false;
  Map<String, dynamic> _resultadosBusca = {};
  String _resumoGeral = '';

  final String _urlBackend = 'https://jussmart-backend.onrender.com/consultar';

  Future<void> _executarBusca() async {
    final termo = _controladorBusca.text.trim();
    if (termo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe os dados para a busca.')),
      );
      return;
    }

    setState(() {
      _carregando = true;
      _resultadosBusca = {};
      _resumoGeral = '';
    });

    try {
      final response = await http.post(
        Uri.parse(_urlBackend),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo': _tipoConsulta,
          'termo': termo,
          'numero_processo': termo,
        }),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        setState(() {
          _resultadosBusca = dados;
          _gerarResumo(dados);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na requisição ao servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao conectar com a API: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _gerarResumo(Map<String, dynamic> dados) {
    int totalProcessos = 0;
    int tribunaisComResultados = 0;

    dados.forEach((key, value) {
      if (value is Map && value.containsKey('total_encontrado')) {
        int qtd = value['total_encontrado'] ?? 0;
        if (qtd > 0) {
          totalProcessos += qtd;
          tribunaisComResultados++;
        }
      }
    });

    setState(() {
      if (totalProcessos > 0) {
        _resumoGeral = 'Resumo da Consulta: Foram localizados $totalProcessos processo(s) em $tribunaisComResultados tribunal(ais) consultado(s).';
      } else {
        _resumoGeral = 'Resumo da Consulta: Nenhum processo foi localizado nos tribunais pesquisados.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'JusSmart',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de Boas-vindas e Identidade Visual
            Card(
              elevation: 0,
              color: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.search_sharp, color: Color(0xFF1E3A8A), size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Consulta Unificada Datajud\nPesquise em até 85 tribunais simultaneamente.',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Seleção do tipo de busca
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('Nº Processo'),
                  selected: _tipoConsulta == 'numero',
                  onSelected: (val) => setState(() => _tipoConsulta = 'numero'),
                  selectedColor: const Color(0xFF1E3A8A),
                  labelStyle: TextStyle(
                    color: _tipoConsulta == 'numero' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ChoiceChip(
                  label: const Text('CPF / CNPJ'),
                  selected: _tipoConsulta == 'cpf',
                  onSelected: (val) => setState(() => _tipoConsulta = 'cpf'),
                  selectedColor: const Color(0xFF1E3A8A),
                  labelStyle: TextStyle(
                    color: _tipoConsulta == 'cpf' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Nome da Parte'),
                  selected: _tipoConsulta == 'nome',
                  onSelected: (val) => setState(() => _tipoConsulta = 'nome'),
                  selectedColor: const Color(0xFF1E3A8A),
                  labelStyle: TextStyle(
                    color: _tipoConsulta == 'nome' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de texto para pesquisa
            TextField(
              controller: _controladorBusca,
              keyboardType: _tipoConsulta == 'nome' ? TextInputType.name : TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: _tipoConsulta == 'numero'
                    ? 'Número do Processo (CNJ)'
                    : _tipoConsulta == 'cpf'
                        ? 'CPF ou CNPJ'
                        : 'Nome Completo da Parte',
                hintText: _tipoConsulta == 'numero'
                    ? 'Ex: 00000000020268170001'
                    : _tipoConsulta == 'cpf'
                        ? 'Ex: 000.000.000-00'
                        : 'Ex: José Rivaldo',
                prefixIcon: const Icon(Icons.manage_search, color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Botão de Pesquisa
            ElevatedButton.icon(
              onPressed: _carregando ? null : _executarBusca,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _carregando ? 'Consultando Tribunais...' : 'Buscar em Todos os Tribunais',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Card do Resumo (exibido apenas após consulta)
            if (_resumoGeral.isNotEmpty) ...[
              Card(
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const Icon(Icons.summarize, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _resumoGeral,
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lista de Resultados por Tribunal
            if (_resultadosBusca.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _resultadosBusca.keys.length,
                itemBuilder: (context, index) {
                  String alias = _resultadosBusca.keys.elementAt(index);
                  var info = _resultadosBusca[alias];
                  if (info is! Map) return const SizedBox.shrink();

                  int total = info['total_encontrado'] ?? 0;
                  String status = info['status'] ?? '';
                  bool encontrou = total > 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: encontrou ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(
                          encontrou ? Icons.check : Icons.close,
                          color: encontrou ? Colors.green.shade800 : Colors.grey,
                        ),
                      ),
                      title: Text(
                        alias.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Status: $status'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: encontrou ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: encontrou ? Colors.green : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '$total processo(s)',
                          style: TextStyle(
                            color: encontrou ? Colors.green.shade900 : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            else if (!_carregando)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Selecione a modalidade de busca, preencha o termo e clique em buscar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
