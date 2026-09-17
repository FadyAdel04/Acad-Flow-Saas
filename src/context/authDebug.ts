function isDev() {
  return typeof import.meta !== 'undefined' && Boolean(import.meta.env?.DEV);
}

let providerRenderCount = 0;

export function bumpAuthProviderRender() {
  providerRenderCount += 1;
  if (!isDev()) return providerRenderCount;
  console.debug('[auth] AuthProvider render', { count: providerRenderCount });
  return providerRenderCount;
}

export function logAuthEvent(event: string, details?: Record<string, unknown>) {
  if (!isDev()) return;
  console.info(`[auth] AUTH EVENT: ${event}`, details ?? {});
}

export function logAuthStateChange(
  label: string,
  details?: Record<string, unknown>
) {
  if (!isDev()) return;
  console.debug(`[auth] ${label}`, details ?? {});
}
