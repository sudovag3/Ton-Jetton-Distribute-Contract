import { z } from 'zod';

export const DistributeSchema = z.object({
    contractAddress: z.string(),
    recipients: z.record(z.string(), z.string()),
});

export const DistributeJettonSchema = z.object({
    contractAddress: z.string(),
    jettonWalletAddress: z.string(),
    responseDestination: z.string(),
    jettonMasterAddress: z.string(),
    recipients: z.record(z.string(), z.number()),
});