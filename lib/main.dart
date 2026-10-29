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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TelaConsultaProcesso(),
    );
  }
}

class TelaConsultaProcesso extends StatefulWidget {
  const TelaConsultaProcesso({super.key});

  @override
  State<TelaConsultaProcesso> createState() => _TelaConsultaProcessoState();
}

class _TelaConsultaProcessoState extends State<TelaConsultaProcesso> {
  final TextEditingController _controladorNumero = TextEditingController();
  bool _carregando = false;
  Map<String, dynamic> _resultadosBusca = {};

  final String _urlBackend = 'https://jussmart-backend.onrender.com/consultar';

  Future<void> _executarBusca() async {
    if (_controladorNumero.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o número do processo.')),
      );
      return;
    }

    setState(() {
      _carregando = true;
      _resultadosBusca = {};
    });

    try {
      final response = await http.post(
        Uri.parse(_urlBackend),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'numero_processo': _controladorNumero.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _resultadosBusca = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na requisição: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao conectar ao servidor: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JusSmart - Consulta Unificada'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controladorNumero,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número do Processo (CNJ)',
                hintText: 'Ex: 00000000020268170001',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _carregando ? null : _executarBusca,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _carregando ? null : _executarBusca,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.manage_search),
                label: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Buscar em Todos os 85 Tribunais', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _resultadosBusca.isEmpty
                  ? Center(
                      child: Text(
                        _carregando
                            ? 'Consultando os tribunais, aguarde...'
                            : 'Digite o número e clique em buscar para iniciar.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _resultadosBusca.keys.length,
                      itemBuilder: (context, index) {
                        String alias = _resultadosBusca.keys.elementAt(index);
                        var info = _resultadosBusca[alias];
                        int total = info['total_encontrado'] ?? 0;
                        String status = info['status'] ?? '';
                        bool encontrou = total > 0;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              encontrou ? Icons.check_circle : Icons.remove_circle_outline,
                              color: encontrou ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              alias.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Status: $status'),
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: encontrou ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$total processos',
                                style: TextStyle(
                                  color: encontrou ? Colors.green.shade900 : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
