import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_controller.dart';
import '../../data/api.dart';
import '../../domain/models.dart';
import '../../domain/money.dart';
import '../theme/app_theme.dart';

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
        scrollable: true,
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
          scrollable: true,
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

  Future<void> _loadConflict() => _run(() async {
    await widget.controller.loadConflictServerData();
  });

  Future<void> _replaceServer() => _run(() async {
    final reviewedEtag = widget.controller.conflictReviewEtag;
    if (reviewedEtag == null) {
      throw ApiException('Atualize a comparação antes de decidir.');
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usar dados deste aparelho?'),
        content: const Text(
          'Os dados deste aparelho substituirão todos os lançamentos, fundos, '
          'orçamentos e metas que estão no servidor. Alterações feitas em outro '
          'aparelho poderão se perder. Salve uma cópia local antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Substituir no servidor'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await widget.controller.replaceRemoteWithLocal(reviewedEtag);
    _notice('Dados deste aparelho confirmados pelo servidor.');
  });

  Future<void> _exportUnreadable() => _run(() async {
    final raw = await widget.controller.readUnreadableDraft();
    if (raw == null) throw ApiException('O rascunho não está mais disponível.');
    await _shareJson(
      {'format': 'financelab-raw-draft-v1', 'rawDraft': raw},
      'rascunho-ilegivel',
      'Cópia de rascunho FinanceLab',
    );
  });

  Future<void> _discardUnreadable() => _run(() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar rascunho local?'),
        content: const Text(
          'O app não conseguiu ler este rascunho. Os dados do servidor não '
          'serão alterados. Se quiser guardar o arquivo para análise, tente '
          'salvar uma cópia antes de descartar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar rascunho'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await widget.controller.discardUnreadableDraft();
    _notice(
      'Rascunho ilegível descartado. Os dados do servidor foram mantidos.',
    );
  });

  Widget _snapshotSummary(FinanceData data) {
    final totalIncome = data.transactions
        .where((item) => item.kind == 'income')
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    final totalOutflow = data.transactions
        .where((item) => item.kind != 'income')
        .fold<int>(0, (sum, item) => sum + item.amountCents);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${data.transactions.length} lançamentos, '
          '${data.funds.length} fundos e '
          '${data.budgets.length} orçamentos',
        ),
        Text('Receitas registradas: ${Money.formatBr(totalIncome)}'),
        Text('Saídas registradas: ${Money.formatBr(totalOutflow)}'),
        Text(
          'Meta de reserva: '
          '${Money.formatBr(data.goals.emergencyFundCents)}',
        ),
      ],
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus dados e privacidade')),
    body: ListView(
      padding:
          EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width > 800
                ? (MediaQuery.sizeOf(context).width - 768) / 2
                : AppSpacing.md,
            vertical: AppSpacing.md,
          ).copyWith(
            bottom: AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
          ),
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
        if (widget.controller.unreadableDraft) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.controller.draftReadFailed
                        ? 'Rascunho indisponível'
                        : 'Rascunho ilegível',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A edição está pausada para não substituir o arquivo '
                    'danificado. Os dados do servidor continuam disponíveis.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: _busy ? null : _exportUnreadable,
                        child: const Text('Tentar salvar cópia'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _discardUnreadable,
                        child: const Text('Descartar rascunho ilegível'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.controller.conflictDetected) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Revisar versões',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Há alterações diferentes neste aparelho e no servidor. '
                    'A comparação abaixo resume os dados; salve uma cópia em '
                    'JSON para examinar todos os registros antes de substituir.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Neste aparelho',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  _snapshotSummary(widget.controller.data),
                  const SizedBox(height: 12),
                  Text(
                    'No servidor',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (widget.controller.conflictingServerData
                      case final server?)
                    _snapshotSummary(server)
                  else
                    const Text('Toque em Atualizar comparação para carregar.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : _loadConflict,
                        child: const Text('Atualizar comparação'),
                      ),
                      FilledButton.tonal(
                        onPressed: _busy ? null : _exportLocal,
                        child: const Text('Salvar cópia local'),
                      ),
                      FilledButton(
                        onPressed:
                            _busy ||
                                widget.controller.conflictReviewEtag == null
                            ? null
                            : _replaceServer,
                        child: const Text('Usar dados deste aparelho'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _discardLocal,
                        child: const Text('Usar dados do servidor'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
