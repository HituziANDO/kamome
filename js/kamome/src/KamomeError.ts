/**
 * Error types defined by Kamome library.
 */
export const KamomeError = {
  requestTimeout: 'RequestTimeout',
  rejected: 'Rejected',
  canceled: 'Canceled',
} as const;
export type KamomeError = (typeof KamomeError)[keyof typeof KamomeError];
