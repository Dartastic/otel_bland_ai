// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_bland_ai/otel_bland_ai.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_bland_ai-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('call.send records pathway + length + price + transfer', () async {
    await tracedBlandAi<String>(
      operation: 'call.send',
      invoke: () async => const BlandAiCallResult(
        value: 'ok',
        result: BlandAiResult(
          callId: 'c_1',
          pathwayId: 'pw_intake',
          pathwayVersion: 'v3',
          callType: 'outbound',
          completed: true,
          callLength: 2.5,
          callPrice: 0.225,
          queueLengthSec: 3,
          transferred: true,
          transferToNumber: '+15555550199',
          summaryGenerated: true,
          recordingUrlPresent: true,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('bland_ai call.send')!);
    expect(a['bland_ai.pathway.id'], 'pw_intake');
    expect(a['bland_ai.pathway.version'], 'v3');
    expect(a['bland_ai.call.length_min'], 2.5);
    expect(a['bland_ai.call.price_usd'], 0.225);
    expect(a['bland_ai.call.transferred'], true);
  });

  test('agent_error sets span error', () async {
    await tracedBlandAi<String>(
      operation: 'call.get',
      invoke: () async => const BlandAiCallResult(
        value: 'ok',
        result: BlandAiResult(
          callId: 'c_2',
          completed: false,
          errorMessage: 'agent_error',
          callLength: 0.5,
        ),
      ),
    );
    expect(
      spans.findSpanByName('bland_ai call.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('no_answer does NOT set span error', () async {
    await tracedBlandAi<String>(
      operation: 'call.get',
      invoke: () async => const BlandAiCallResult(
        value: 'ok',
        result: BlandAiResult(
          completed: false,
          errorMessage: 'no_answer',
        ),
      ),
    );
    expect(
      spans.findSpanByName('bland_ai call.get')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutBlandAiInstrumentationAsync(() async {
      await tracedBlandAi<String>(
        operation: 'pathway.publish',
        invoke: () async => const BlandAiCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('bland_ai '), isEmpty);
  });
}
