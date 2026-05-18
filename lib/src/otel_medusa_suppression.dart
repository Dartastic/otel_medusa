// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_medusa_suppress;

bool medusaInstrumentationSuppressed() => Zone.current[_suppressKey] == true;

T runWithoutMedusaInstrumentation<T>(T Function() body) =>
    runZoned(body, zoneValues: {_suppressKey: true});

Future<T> runWithoutMedusaInstrumentationAsync<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: {_suppressKey: true});
