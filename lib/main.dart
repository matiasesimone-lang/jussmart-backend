import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TelaPrincipalJusSmart(),
    );
  }
}

class TelaPrincipalJusSmart extends StatefulWidget {
  const TelaPrincipalJusSmart({super.key});

  @override
  State<TelaPrincipalJusSmart> createState() => _TelaPrincipalJusSmartState();
}

class _TelaPrincipalJusSmartState extends State<TelaPrincipalJusSmart> {
  int _abaAtiva = 1;
  
  final TextEditingController _controladorBuscaExterna = TextEditingController();
  String _tipoConsulta = 'nome'; // Padrão
  bool _carregando = false;
  Map<String, dynamic> _resultadosBusca = {};
  String _resumoGeral = '';

  final String _urlBackend = 'https://jussmart-backend.onrender.com/consultar';

  Future<void> _executarBuscaExterna() async {
    final termo = _controladorBuscaExterna.text.trim();
    if (termo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o termo para busca.')),
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
          SnackBar(content: Text('Erro no servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão com o servidor: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _gerarResumo(Map<String, dynamic> dados) {
    int totalProcessos = 0;
    int tribunaisEncontrados = 0;

    dados.forEach((key, value) {
      if (value is Map && value.containsKey('total_encontrado')) {
        int qtd = value['total_encontrado'] ?? 0;
        if (qtd > 0) {
          totalProcessos += qtd;
          tribunaisEncontrados++;
        }
      }
    });

    setState(() {
      if (totalProcessos > 0) {
        _resumoGeral = 'Localizados $totalProcessos processo(s) em $tribunaisEncontrados tribunal(ais).';
      } else {
        _resumoGeral = 'Nenhum processo encontrado nos 85 tribunais consultados.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        title: const Text(
          'JusSmart',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.star, color: Color(0xFF84CC16), size: 32),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.balance, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'JusSmart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Plataforma Processual',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Gestão de Processos e Consulta Externa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Abas Principais
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _abaAtiva = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _abaAtiva == 0
                            ? const Color(0xFF06B6D4)
                            : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.assignment, size: 16),
                      label: const Text(
                        'Minha Central',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _abaAtiva = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _abaAtiva == 1
                            ? const Color(0xFF06B6D4)
                            : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text(
                        'Busca Externa',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_abaAtiva == 1) ...[
                // Botoes de Selecao com Layout Adaptavel (Sem corte de tela)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: [
                        ChoiceChip(
                          label: const Text('Nº Processo', style: TextStyle(fontSize: 11)),
                          selected: _tipoConsulta == 'numero',
                          onSelected: (val) => setState(() {
                            _tipoConsulta = 'numero';
                            _controladorBuscaExterna.clear();
                          }),
                          selectedColor: const Color(0xFF06B6D4),
                        ),
                        ChoiceChip(
                          label: const Text('CPF / CNPJ', style: TextStyle(fontSize: 11)),
                          selected: _tipoConsulta == 'cpf',
                          onSelected: (val) => setState(() {
                            _tipoConsulta = 'cpf';
                            _controladorBuscaExterna.clear();
                          }),
                          selectedColor: const Color(0xFF06B6D4),
                        ),
                        ChoiceChip(
                          label: const Text('Nome Parte', style: TextStyle(fontSize: 11)),
                          selected: _tipoConsulta == 'nome',
                          onSelected: (val) => setState(() {
                            _tipoConsulta = 'nome';
                            _controladorBuscaExterna.clear();
                          }),
                          selectedColor: const Color(0xFF06B6D4),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Campo de Texto com troca forcada de Teclado (Key dinamica)
                TextField(
                  key: ValueKey(_tipoConsulta),
                  controller: _controladorBuscaExterna,
                  keyboardType: _tipoConsulta == 'nome' ? TextInputType.text : TextInputType.number,
                  inputFormatters: _tipoConsulta == 'cpf' ? [CpfCnpjInputFormatter()] : null,
                  textCapitalization: _tipoConsulta == 'nome' ? TextCapitalization.words : TextCapitalization.none,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _tipoConsulta == 'numero'
                        ? 'Número do Processo (CNJ)'
                        : _tipoConsulta == 'cpf'
                            ? 'CPF ou CNPJ'
                            : 'Nome Completo da Parte',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                    hintText: _tipoConsulta == 'numero'
                        ? 'Ex: 00000000020268170001'
                        : _tipoConsulta == 'cpf'
                            ? 'Digite apenas números'
                            : 'Ex: José Rivaldo Matias',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.manage_search, color: Color(0xFF06B6D4)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _carregando ? null : _executarBuscaExterna,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _carregando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _carregando ? 'Consultando Tribunais...' : 'Buscar nos 85 Tribunais',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),

                if (_resumoGeral.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF059669)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resumoGeral,
                            style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_resultadosBusca.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _resultadosBusca.keys.length,
                    itemBuilder: (context, index) {
                      String alias = _resultadosBusca.keys.elementAt(index);
                      var info = _resultadosBusca[alias];
                      if (info is! Map) return const SizedBox.shrink();

                      int total = info['total_encontrado'] ?? 0;
                      List processos = info['processos'] ?? [];

                      if (total == 0) return const SizedBox.shrink();

                      return Card(
                        color: const Color(0xFF0F172A),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: Text(
                            alias.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '$total processo(s) localizado(s)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          children: processos.map<Widget>((proc) {
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Processo: ${proc['numeroProcesso'] ?? 'N/A'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Classe: ${proc['classe']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text('Status: ${proc['status']}', style: TextStyle(color: proc['status'] == 'Ativo' ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text('Última Movimentação (${proc['ultimaMovimentacao']['data']}):', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('${proc['ultimaMovimentacao']['nome']}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Text('Previsão: ${proc['previsaoProximoAndamento']}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontStyle: FontStyle.italic)),
                                  const Divider(color: Colors.white24),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 14) text = text.substring(0, 14);

    String formatted = '';
    if (text.length <= 11) {
      for (int i = 0; i < text.length; i++) {
        if (i == 3 || i == 6) formatted += '.';
        if (i == 9) formatted += '-';
        formatted += text[i];
      }
    } else {
      for (int i = 0; i < text.length; i++) {
        if (i == 2 || i == 5) formatted += '.';
        if (i == 8) formatted += '/';
        if (i == 12) formatted += '-';
        formatted += text[i];
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
