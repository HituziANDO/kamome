import { KamomeEventData } from './KamomeEventData.ts';
import { KamomeEventResult } from './KamomeEventResult.ts';

export type KamomeRequest = {
  id: string;
  name: string;
  data?: KamomeEventData | null;
  timeout: number;
  resolve: (data: KamomeEventResult | null) => void;
  reject: (reason: string) => void;
};
