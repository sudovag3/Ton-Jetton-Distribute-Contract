export interface DistributeDto {
    contractAddress: string;
    recipients: { [key: string]: number };
}

export interface DistributeJettonDto {
    contractAddress: string;
    jettonWalletAddress: string;
    jettonMasterAddress: string;
    responseDestination: string;
    recipients: { [key: string]: number };
}