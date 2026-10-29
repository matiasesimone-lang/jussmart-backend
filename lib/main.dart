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
  int _abaAtiva = 0; // 0: Minha Central, 1: Busca Externa
  String _filtroStatus = 'todos'; // todos, ativos, inativos
  
  // Dados de busca externa
  final TextEditingController _controladorBuscaExterna = TextEditingController();
  String _tipoConsulta = 'numero'; // 'numero', 'cpf', 'nome'
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge JusSmart com Ícone de Balança
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.balance, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'JusSmart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Título e Subtítulo
              const Text(
                'Plataforma Processual',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestão de Processos e Consulta Externa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Botões Principais: Minha Central e Busca Externa
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.assignment, size: 18),
                      label: const Text(
                        'Minha Central',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _abaAtiva = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _abaAtiva == 1
                            ? const Color(0xFF06B6D4)
                            : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text(
                        'Busca Externa',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conteúdo da Aba 0: Minha Central
              if (_abaAtiva == 0) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Cadastrar Processo',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Repor\nDados',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo de Filtro Local
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Filtrar lista por nº, assunto ou vara...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Abas de Status: Todos (0), Ativos (0), Inativos (0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusTab('Todos (0)', 'todos', null),
                      _buildStatusTab('Ativos (0)', 'ativos', const Color(0xFF84CC16)),
                      _buildStatusTab('Inativos (0)', 'inativos', const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ],

              // Conteúdo da Aba 1: Busca Externa Datajud
              if (_abaAtiva == 1) ...[
                // Seleção do tipo de consulta externa
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Nº Processo'),
                      selected: _tipoConsulta == 'numero',
                      onSelected: (val) => setState(() {
                        _tipoConsulta = 'numero';
                        _controladorBuscaExterna.clear();
                      }),
                      selectedColor: const Color(0xFF06B6D4),
                    ),
                    ChoiceChip(
                      label: const Text('CPF / CNPJ'),
                      selected: _tipoConsulta == 'cpf',
                      onSelected: (val) => setState(() {
                        _tipoConsulta = 'cpf';
                        _controladorBuscaExterna.clear();
                      }),
                      selectedColor: const Color(0xFF06B6D4),
                    ),
                    ChoiceChip(
                      label: const Text('Nome Parte'),
                      selected: _tipoConsulta == 'nome',
                      onSelected: (val) => setState(() {
                        _tipoConsulta = 'nome';
                        _controladorBuscaExterna.clear();
                      }),
                      selectedColor: const Color(0xFF06B6D4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Campo de Entrada para Busca Externa
                TextField(
                  controller: _controladorBuscaExterna,
                  keyboardType: _tipoConsulta == 'nome' ? TextInputType.text : TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _tipoConsulta == 'numero'
                        ? 'Número do Processo (CNJ)'
                        : _tipoConsulta == 'cpf'
                            ? 'CPF ou CNPJ'
                            : 'Nome Completo da Parte',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: _tipoConsulta == 'numero'
                        ? 'Ex: 00000000020268170001'
                        : _tipoConsulta == 'cpf'
                            ? 'Ex: 000.000.000-00'
                            : 'Ex: José Rivaldo',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.manage_search, color: Color(0xFF06B6D4)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Botão de Pesquisa Externa nos 85 Tribunais
                ElevatedButton.icon(
                  onPressed: _carregando ? null : _executarBuscaExterna,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),

                // Card de Resumo do Resultado
                if (_resumoGeral.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF059669)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resumoGeral,
                            style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Lista de Resultados
                if (_resultadosBusca.isNotEmpty) ...[
                  const SizedBox(height: 14),
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
                        color: const Color(0xFF0F172A),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            alias.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'Status: $status',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: encontrou ? const Color(0xFF065F46) : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$total processos',
                              style: TextStyle(
                                color: encontrou ? const Color(0xFF34D399) : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
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

  Widget _buildStatusTab(String label, String statusKey, Color? indicatorColor) {
    bool selecionado = _filtroStatus == statusKey;
    return GestureDetector(
      onTap: () => setState(() => _filtroStatus = statusKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF334155) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (indicatorColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
