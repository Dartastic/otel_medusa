// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_medusa/otel_medusa.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_medusa-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) => {
    for (final a in s.attributes.toList()) a.key: a.value,
  };

  test('carts.complete records api + region + payment status', () async {
    await tracedMedusa<String>(
      operation: 'carts.complete',
      api: 'store',
      invoke: () async => const MedusaCallResult(
        value: 'ok',
        result: MedusaResult(
          api: 'store',
          regionId: 'reg-us',
          salesChannelId: 'sc-1',
          orderStatus: 'pending',
          paymentStatus: 'awaiting',
          fulfillmentStatus: 'not_fulfilled',
          totalAmountMinor: 8900,
          currency: 'USD',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('medusa carts.complete')!);
    expect(a['medusa.api'], 'store');
    expect(a['medusa.region.id'], 'reg-us');
    expect(a['medusa.sales_channel.id'], 'sc-1');
    expect(a['medusa.payment.status'], 'awaiting');
    expect(a['medusa.amount.total.minor'], 8900);
  });

  test('canceled order sets span error', () async {
    await tracedMedusa<String>(
      operation: 'orders.retrieve',
      invoke: () async => const MedusaCallResult(
        value: 'ok',
        result: MedusaResult(orderStatus: 'canceled'),
      ),
    );
    expect(
      spans.findSpanByName('medusa orders.retrieve')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutMedusaInstrumentationAsync(() async {
      await tracedMedusa<String>(
        operation: 'products.list',
        invoke: () async => const MedusaCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('medusa '), isEmpty);
  });
}
