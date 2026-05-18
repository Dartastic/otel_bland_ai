// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_bland_ai_suppression.dart';

const _tracerName = 'dartastic_otel_libs_bland_ai';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class BlandAiResult {
  const BlandAiResult({
    this.callId,
    this.batchId,
    this.pathwayId,
    this.pathwayVersion,
    this.callType,
    this.completed,
    this.errorMessage,
    this.callLength,
    this.callPrice,
    this.queueLengthSec,
    this.transferToNumber,
    this.transferred,
    this.summaryGenerated,
    this.recordingUrlPresent,
    this.voicemailDetected,
    this.statusCode,
  });

  final String? callId;

  /// Bland batch id (for `send_batch` mass dialing).
  final String? batchId;

  /// Conversational Pathways graph id — Bland's defining feature
  /// (vs Vapi's prompt+tools model).
  final String? pathwayId;

  /// Pathway version (Bland versions every published change).
  final String? pathwayVersion;

  /// `outbound` / `inbound` / `web`.
  final String? callType;

  /// `true` when the call ended via Bland's natural completion path
  /// vs cut short by error/disconnect.
  final bool? completed;

  /// Bland's error message string when status indicates failure.
  /// Examples: `agent_error` / `no_answer` / `busy` / `transfer_failed`
  /// / `pipeline_timeout` / `voicemail_max_duration`.
  final String? errorMessage;

  /// Call length in minutes (Bland's primary billing unit — billed
  /// per minute).
  final double? callLength;

  /// Per-call price in USD.
  final double? callPrice;

  /// Time spent queued before dispatch.
  final int? queueLengthSec;

  /// Number the call was warm-transferred to (without PII content).
  final String? transferToNumber;

  final bool? transferred;
  final bool? summaryGenerated;
  final bool? recordingUrlPresent;
  final bool? voicemailDetected;

  final int? statusCode;
}

class BlandAiCallResult<T> {
  const BlandAiCallResult({required this.value, this.result});
  final T value;
  final BlandAiResult? result;
}

/// Wraps a Bland.ai API call in a CLIENT span. [operation] is one of
/// `call.send`, `call.send_batch`, `call.analyze`, `call.get`,
/// `call.stop`, `pathway.create`, `pathway.update`, `pathway.publish`,
/// `voices.list`, `voices.clone`, `inbound.purchase`.
Future<T> tracedBlandAi<T>({
  required String operation,
  required Future<BlandAiCallResult<T>> Function() invoke,
}) async {
  if (blandAiInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'bland_ai',
    'rpc.method': operation,
    'bland_ai.operation': operation,
  };

  final span = _tracer().startSpan(
    'bland_ai $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.callId != null) {
        extras.add(OTel.attributeString(
          'bland_ai.call.id',
          r.result!.callId!,
        ));
      }
      if (r.result!.batchId != null) {
        extras.add(OTel.attributeString(
          'bland_ai.batch.id',
          r.result!.batchId!,
        ));
      }
      if (r.result!.pathwayId != null) {
        extras.add(OTel.attributeString(
          'bland_ai.pathway.id',
          r.result!.pathwayId!,
        ));
      }
      if (r.result!.pathwayVersion != null) {
        extras.add(OTel.attributeString(
          'bland_ai.pathway.version',
          r.result!.pathwayVersion!,
        ));
      }
      if (r.result!.callType != null) {
        extras.add(OTel.attributeString(
          'bland_ai.call.type',
          r.result!.callType!,
        ));
      }
      if (r.result!.completed != null) {
        extras.add(OTel.attributeBool(
          'bland_ai.call.completed',
          r.result!.completed!,
        ));
      }
      if (r.result!.errorMessage != null) {
        extras.add(OTel.attributeString(
          'bland_ai.call.error_message',
          r.result!.errorMessage!,
        ));
        if (r.result!.errorMessage == 'agent_error' ||
            r.result!.errorMessage == 'pipeline_timeout' ||
            r.result!.errorMessage == 'transfer_failed') {
          span.setStatus(
            SpanStatusCode.Error,
            'Bland error ${r.result!.errorMessage}',
          );
        }
      }
      if (r.result!.callLength != null) {
        extras.add(OTel.attributeDouble(
          'bland_ai.call.length_min',
          r.result!.callLength!,
        ));
      }
      if (r.result!.callPrice != null) {
        extras.add(OTel.attributeDouble(
          'bland_ai.call.price_usd',
          r.result!.callPrice!,
        ));
      }
      if (r.result!.queueLengthSec != null) {
        extras.add(OTel.attributeInt(
          'bland_ai.queue.length_sec',
          r.result!.queueLengthSec!,
        ));
      }
      if (r.result!.transferToNumber != null) {
        extras.add(OTel.attributeString(
          'bland_ai.transfer.to_number',
          r.result!.transferToNumber!,
        ));
      }
      if (r.result!.transferred != null) {
        extras.add(OTel.attributeBool(
          'bland_ai.call.transferred',
          r.result!.transferred!,
        ));
      }
      if (r.result!.summaryGenerated != null) {
        extras.add(OTel.attributeBool(
          'bland_ai.summary.generated',
          r.result!.summaryGenerated!,
        ));
      }
      if (r.result!.recordingUrlPresent != null) {
        extras.add(OTel.attributeBool(
          'bland_ai.recording.present',
          r.result!.recordingUrlPresent!,
        ));
      }
      if (r.result!.voicemailDetected != null) {
        extras.add(OTel.attributeBool(
          'bland_ai.voicemail.detected',
          r.result!.voicemailDetected!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Bland HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
