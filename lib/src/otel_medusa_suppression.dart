// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_medusa_suppress;

bool medusaInstrumentationSuppressed() => Zone.current[_suppressKey] == true;

T runWithoutMedusaInstrumentation<T>(T Function() body) =>
    runZoned(body, zoneValues: {_suppressKey: true});

Future<T> runWithoutMedusaInstrumentationAsync<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: {_suppressKey: true});
