// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_medusa/otel_medusa.dart';

/// Traces Medusa calls with OpenTelemetry.
///
/// `otel_medusa` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Medusa call in
/// [tracedMedusa]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'medusa-example');

  // Wraps a Medusa API call in a CLIENT span.
  final medusaId = await tracedMedusa<String>(
    operation: 'products.create',
    api: 'example',
    invoke: () async {
      // Make the Medusa call here, then report what it returned.
      const id = 'medusa_8f3a2c';
      return const MedusaCallResult(
          value: id,
          result: MedusaResult(
              itemCount: 3,
              totalCount: 3,
              api: 'admin',
              regionId: 'region_id',
              salesChannelId: 'sales_channel_id',
              orderStatus: 'pending',
              paymentStatus: 'not_paid',
              fulfillmentStatus: 'not_fulfilled',
              totalAmountMinor: 1999,
              currency: 'usd',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedMedusa products.create returned $medusaId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMedusaInstrumentationAsync.
  await runWithoutMedusaInstrumentationAsync(
    () => tracedMedusa<String>(
      operation: 'products.create',
      api: 'example',
      invoke: () async {
        const id = 'medusa_8f3a2c';
        return const MedusaCallResult(
            value: id,
            result: MedusaResult(
                itemCount: 3,
                totalCount: 3,
                api: 'admin',
                regionId: 'region_id',
                salesChannelId: 'sales_channel_id',
                orderStatus: 'pending',
                paymentStatus: 'not_paid',
                fulfillmentStatus: 'not_fulfilled',
                totalAmountMinor: 1999,
                currency: 'usd',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
