import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_controller.dart';
import '../../data/api.dart';

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      _notice(error.message, error: true);
    } on FormatException catch (_) {
      _notice('O arquivo não contém dados financeiros válidos.', error: true);
    } catch (_) {
      _notice(
        'Não foi possível concluir esta operação. Tente novamente.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _shareJson(
    Map<String, dynamic> payload,
    String prefix,
    String subject,
  ) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: '$prefix-$stamp.json',
          ),
        ],
      ),
    );
  }

  Future<void> _export() => _run(() async {
    final payload = await widget.controller.exportPersonalData();
    await _shareJson(payload, 'meus-dados', 'Meus dados FinanceLab');
  });

  Future<void> _exportLocal() => _run(() async {
    await _shareJson(
      widget.controller.exportLocalFinanceData(),
      'dados-financeiros-locais',
      'Cópia local FinanceLab',
    );
  });

  Future<void> _import() => _run(() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return;
    final size = file.lengthSync() ?? await file.length();
    if (size == null || size > 5 * 1024 * 1024) {
      throw const FormatException('Arquivo maior que 5 MB');
    }
    final bytes = await file.readAsBytes();
    final source = utf8.decode(bytes);
    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Substituir dados financeiros?'),
        content: const Text(
          'A importação substituirá lançamentos, fundos, orçamentos e metas da sua conta. Esta ação será salva no servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Importar e substituir'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await widget.controller.importFinanceDataJson(source);
    _notice(
      widget.controller.demo
          ? 'Dados importados na demonstração. Eles serão descartados ao sair.'
          : 'Dados importados. Aguarde a confirmação de salvamento.',
    );
  });

  Future<void> _requestErasure() => _run(() async {
    final reason = TextEditingController();
    try {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Solicitar eliminação de dados?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O pedido será encaminhado para tratamento conforme a LGPD. Você perderá acesso aos dados quando ele for concluído.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enviar pedido'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      final result = await widget.controller.requestErasure(
        reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
      );
      final dueAt = result['dueAt']?.toString();
      _notice(
        dueAt == null
            ? 'Pedido de eliminação registrado.'
            : 'Pedido registrado. Prazo informado: ${_formatDate(dueAt)}.',
      );
    } finally {
      reason.dispose();
    }
  });

  Future<void> _discardLocal() => _run(() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar alterações locais?'),
        content: const Text(
          'Os dados do servidor substituirão as alterações pendentes neste '
          'aparelho. Salve uma cópia local em JSON antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar e recarregar'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await widget.controller.discardPendingChanges();
    _notice('Dados do servidor recarregados.');
  });

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus dados e privacidade')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Controle dos seus dados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Exporte uma cópia dos dados pessoais, restaure um arquivo financeiro ou registre uma solicitação de eliminação.',
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.save_alt_outlined),
            title: const Text('Salvar cópia local'),
            subtitle: const Text(
              'Compartilhe um JSON com os dados mostrados neste aparelho, '
              'inclusive alterações pendentes',
            ),
            enabled: !_busy,
            onTap: _busy ? null : _exportLocal,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exportar meus dados'),
            subtitle: const Text(
              'Compartilhe um JSON autenticado com seus dados pessoais e financeiros',
            ),
            enabled: !_busy && !widget.controller.demo,
            onTap: _busy || widget.controller.demo ? null : _export,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Importar dados financeiros'),
            subtitle: const Text(
              'Restaure lançamentos, fundos, orçamentos e metas de um JSON',
            ),
            enabled: !_busy,
            onTap: _busy ? null : _import,
          ),
        ),
        if (widget.controller.hasUnsavedChanges && !widget.controller.demo)
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Descartar alterações pendentes'),
              subtitle: const Text(
                'Recarregue os dados do servidor após salvar uma cópia local',
              ),
              enabled: !_busy,
              onTap: _busy ? null : _discardLocal,
            ),
          ),
        const SizedBox(height: 20),
        Text('LGPD', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Solicitar eliminação dos dados'),
            subtitle: const Text(
              'Registre um pedido para análise e atendimento',
            ),
            enabled: !_busy && !widget.controller.demo,
            onTap: _busy || widget.controller.demo ? null : _requestErasure,
          ),
        ),
        if (widget.controller.demo) ...[
          const SizedBox(height: 12),
          const Text(
            'Exportação e solicitação LGPD exigem uma conta conectada.',
          ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}
