/*
 * Altar call / commitment form. Ported from js/screens/commit.js.
 * If Config.commitSubmitUrl is set → POST JSON. Otherwise (or if the POST fails)
 * the answer is saved on this phone.
 */
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/event_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _options = ['deepen', 'serve', 'sacraments', 'contact'];
const _other = 'other';

class CommitScreen extends StatefulWidget {
  /// "Back to Home" on the thank-you view.
  final VoidCallback? onHome;
  const CommitScreen({super.key, this.onHome});

  @override
  State<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends State<CommitScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  String? _parish; // null until chosen; '' never used
  final Set<String> _responses = {};
  Map<String, String?> _err = {};
  bool _sending = false;
  // To bring the first field with an error into view (the web app focused it).
  final _keys = {'name': GlobalKey(), 'parish': GlobalKey(), 'contact': GlobalKey(), 'resp': GlobalKey()};
  final _nameFocus = FocusNode(), _contactFocus = FocusNode();
  String? _done; // 'remote' | 'local' → thank-you view

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    _nameFocus.dispose();
    _contactFocus.dispose();
    super.dispose();
  }

  static bool _validContact(String v) {
    final s = v.trim();
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s)) return true;
    return s.replaceAll(RegExp(r'\D'), '').length >= 10; // US phone: 10+ digits
  }

  Future<String> _send(Map<String, dynamic> entry) async {
    Future<String> local() async {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('roe.commitments') ?? [];
      list.add(jsonEncode(entry));
      await prefs.setStringList('roe.commitments', list);
      return 'local';
    }

    if (Config.commitSubmitUrl.isEmpty) return local();
    try {
      final r = await http
          .post(Uri.parse(Config.commitSubmitUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode(entry))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('HTTP ${r.statusCode}');
      return 'remote';
    } catch (_) {
      return local();
    }
  }

  Future<void> _submit(AppState app) async {
    final i = app.i;
    final parish = _parish ?? (app.parishId.isNotEmpty ? app.parishId : null);
    setState(() {
      _err = {
        'name': _name.text.trim().isEmpty ? i.t('errName') : null,
        'parish': parish == null ? i.t('errParish') : null,
        'contact': _validContact(_contact.text) ? null : i.t('errContact'),
        'resp': _responses.isEmpty ? i.t('errResponse') : null,
      };
    });
    if (_err.values.any((e) => e != null)) {
      final first = ['name', 'parish', 'contact', 'resp'].firstWhere((k) => _err[k] != null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[first]?.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.15);
        if (first == 'name') _nameFocus.requestFocus();
        if (first == 'contact') _contactFocus.requestFocus();
      });
      return;
    }

    setState(() => _sending = true);
    final p = parish == _other ? null : parishById(parish!);
    final where = await _send({
      'name': _name.text.trim(),
      'parishId': parish,
      'parishName': p?.label ?? i.t('parishOther'),
      'contact': _contact.text.trim(),
      'responses': _responses.toList(),
      'note': _note.text.trim(),
      'lang': app.lang,
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      _done = where;
    });
  }

  void _again() => setState(() {
        _done = null;
        _name.clear();
        _contact.clear();
        _note.clear();
        _responses.clear();
        _err = {};
      });

  Widget _error(String key) {
    final e = _err[key];
    if (e == null) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(e, style: T.body(13, color: C.red, weight: FontWeight.w600)),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s.toUpperCase(), style: T.label()),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = app.i;

    if (_done != null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          child: Column(children: [
            const CircleAvatar(radius: 32, backgroundColor: C.green, child: Icon(Icons.check, color: C.white, size: 38)),
            const SizedBox(height: 14),
            Text(i.t('thanksTitle'), textAlign: TextAlign.center, style: T.head(24, color: C.green)),
            const SizedBox(height: 8),
            Text(i.t('thanksText'), textAlign: TextAlign.center, style: T.serif(16)),
            if (_done == 'local') ...[
              const SizedBox(height: 8),
              Text(i.t('savedLocally'), textAlign: TextAlign.center, style: T.body(13, color: C.muted)),
            ],
            const SizedBox(height: 16),
            SmallButton(i.t('backHome'), onTap: widget.onHome ?? () => Navigator.of(context).maybePop()),
            const SizedBox(height: 8),
            TextButton(onPressed: _again, child: Text(i.t('submitAnother'), style: T.body(14, color: C.green, weight: FontWeight.w600))),
          ]),
        ),
      ]);
    }

    final parishValue = _parish ?? (app.parishId.isNotEmpty ? app.parishId : '');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(child: Text(i.t('commitIntro'), style: T.serif(16.5))),
        AppCard(
          title: i.t('commitFormTitle'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            KeyedSubtree(key: _keys['name'], child: _label(i.t('fName'))),
            TextField(controller: _name, focusNode: _nameFocus, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.name]),
            _error('name'),
            KeyedSubtree(key: _keys['parish'], child: _label(i.t('yourParish'))),
            ParishPicker(selectedId: parishValue == _other ? '' : parishValue, onPick: (id) => setState(() => _parish = id)),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _parish == _other,
              title: Text(i.t('parishOther'), style: T.body(14.5)),
              onChanged: (v) => setState(() => _parish = v == true ? _other : null),
            ),
            _error('parish'),
            KeyedSubtree(key: _keys['contact'], child: _label(i.t('fContact'))),
            TextField(controller: _contact, focusNode: _contactFocus, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email]),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(i.t('fContactHint'), style: T.body(12.5, color: C.muted)),
            ),
            _error('contact'),
            KeyedSubtree(key: _keys['resp'], child: _label(i.t('fResponse'))),
            for (final o in _options)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _responses.contains(o),
                title: Text(i.t('opt_$o'), style: T.body(15)),
                onChanged: (v) => setState(() => v == true ? _responses.add(o) : _responses.remove(o)),
              ),
            _error('resp'),
            _label(i.t('fNote')),
            TextField(controller: _note, maxLines: 3, maxLength: 500),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: C.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _sending ? null : () => _submit(app),
              child: Text(_sending ? i.t('sending') : i.t('submit'), style: T.head(18, color: C.white)),
            ),
            const SizedBox(height: 10),
            Text(i.t('privacyNote'), style: T.body(12.5, color: C.muted)),
          ]),
        ),
      ],
    );
  }
}
