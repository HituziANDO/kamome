import { KamomeEventData } from './KamomeEventData';
import { KamomeEventResult } from './KamomeEventResult';

export type KamomeRequest = {
  id: string;
  name: string;
  data?: KamomeEventData | null;
  timeout: number;
  resolve: (data: KamomeEventResult | null) => void;
  reject: (reason: string) => void;
};
