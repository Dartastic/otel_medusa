// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_medusa_suppression.dart';

const _tracerName = 'dartastic_otel_libs_medusa';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class MedusaResult {
  /// Creates a result.
  const MedusaResult({
    this.itemCount,
    this.totalCount,
    this.api,
    this.regionId,
    this.salesChannelId,
    this.orderStatus,
    this.paymentStatus,
    this.fulfillmentStatus,
    this.totalAmountMinor,
    this.currency,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `count` from paginated responses.
  final int? totalCount;

  /// `admin` / `store` / `auth` — distinct auth + rate limits.
  final String? api;

  /// `region_id` (drives tax, currency, fulfillment).
  final String? regionId;

  /// `sales_channel_id` (storefront identity for inventory rules).
  final String? salesChannelId;

  /// `pending` / `completed` / `archived` / `canceled` /
  /// `requires_action`.
  final String? orderStatus;

  /// `not_paid` / `awaiting` / `captured` / `partially_refunded` /
  /// `refunded` / `canceled` / `requires_action`.
  final String? paymentStatus;

  /// `not_fulfilled` / `partially_fulfilled` / `fulfilled` /
  /// `partially_shipped` / `shipped` / `canceled` /
  /// `partially_returned` / `returned`.
  final String? fulfillmentStatus;

  /// Total in minor units.
  final int? totalAmountMinor;

  /// ISO 4217.
  final String? currency;

  /// `x-medusa-request-id` (when middleware adds it).
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class MedusaCallResult<T> {
  /// Creates a call result.
  const MedusaCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final MedusaResult? result;
}

/// Wraps a Medusa API call in a CLIENT span. [operation] is one of
/// `products.list`, `products.retrieve`, `products.create`,
/// `carts.create`, `carts.add_line_item`, `carts.complete`,
/// `orders.list`, `orders.retrieve`, `orders.capture_payment`,
/// `orders.create_fulfillment`, `orders.create_shipment`,
/// `orders.create_refund`, `customers.list`, `regions.list`,
/// `inventory_items.list`, `webhooks.create`, `auth.token`.
Future<T> tracedMedusa<T>({
  required String operation,
  required Future<MedusaCallResult<T>> Function() invoke,
  String? api,
}) async {
  if (medusaInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'medusa',
    'rpc.method': operation,
    'medusa.operation': operation,
  };
  if (api != null) m['medusa.api'] = api;

  final span = _tracer().startSpan(
    'medusa $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(
          OTelAPI.attributeInt('medusa.item_count', r.result!.itemCount!),
        );
      }
      if (r.result!.totalCount != null) {
        extras.add(
          OTelAPI.attributeInt('medusa.total_count', r.result!.totalCount!),
        );
      }
      if (r.result!.api != null) {
        extras.add(OTelAPI.attributeString('medusa.api', r.result!.api!));
      }
      if (r.result!.regionId != null) {
        extras.add(
          OTelAPI.attributeString('medusa.region.id', r.result!.regionId!),
        );
      }
      if (r.result!.salesChannelId != null) {
        extras.add(
          OTelAPI.attributeString(
            'medusa.sales_channel.id',
            r.result!.salesChannelId!,
          ),
        );
      }
      if (r.result!.orderStatus != null) {
        extras.add(
          OTelAPI.attributeString(
              'medusa.order.status', r.result!.orderStatus!),
        );
        if (r.result!.orderStatus == 'canceled') {
          span.setStatus(SpanStatusCode.Error, 'Medusa order canceled');
        }
      }
      if (r.result!.paymentStatus != null) {
        extras.add(
          OTelAPI.attributeString(
            'medusa.payment.status',
            r.result!.paymentStatus!,
          ),
        );
      }
      if (r.result!.fulfillmentStatus != null) {
        extras.add(
          OTelAPI.attributeString(
            'medusa.fulfillment.status',
            r.result!.fulfillmentStatus!,
          ),
        );
      }
      if (r.result!.totalAmountMinor != null) {
        extras.add(
          OTelAPI.attributeInt(
            'medusa.amount.total.minor',
            r.result!.totalAmountMinor!,
          ),
        );
      }
      if (r.result!.currency != null) {
        extras.add(
          OTelAPI.attributeString('medusa.currency', r.result!.currency!),
        );
      }
      if (r.result!.requestId != null) {
        extras.add(
          OTelAPI.attributeString('medusa.request.id', r.result!.requestId!),
        );
      }
      if (r.result!.statusCode != null) {
        extras.add(
          OTelAPI.attributeInt(
              'http.response.status_code', r.result!.statusCode!),
        );
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Medusa HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(
      OTelAPI.attributes([
        OTelAPI.attributeString(
          ErrorAttributes.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
