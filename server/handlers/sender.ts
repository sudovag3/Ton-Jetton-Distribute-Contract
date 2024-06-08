import {Request, Response, NextFunction} from "express";
import {DistributeDto, DistributeJettonDto} from "../dtos/Distribute.dto";
import {distributeResponse} from "../types/response";
import HttpException from "../exceptions/HttpException";
import { address, beginCell, toNano, Dictionary, DictionaryValue, Address, Cell } from '@ton/core';
import { Blockchain } from '@ton/sandbox';
import { JettonDefaultWallet } from '../../build/Jetton/tact_JettonDefaultWallet';
import {storeTokenTransfer2} from "../../build/Jetton/tact_JettonDefaultWallet"
import { TokenTransfer } from '../../build/Jetton/tact_SampleJetton';
import { loadTokenSendInfo, storeTokenSendInfo, TokenSendInfo } from '../../build/BatchSender/tact_BatchSender';

export function payload_body(tokenRoot: Address, length: bigint, sendInfo: Dictionary<bigint, TokenSendInfo>): Cell {
    return beginCell()
        .storeRef(
            beginCell()
                .storeUint(length, 64) // queryid
                .storeAddress(tokenRoot)
                .endCell()

        )
        .storeRef(
            // internal transfer message
            beginCell()
                .storeUint(0,8)
                .storeDict(sendInfo, Dictionary.Keys.BigInt(257), dictValueParserTokenSendInfo())
                .endCell()
        )
        .endCell();
}
export function dictValueParserTokenSendInfo(): DictionaryValue<TokenSendInfo> {
    return {
        serialize: (src, buidler) => {
            buidler.storeRef(beginCell().store(storeTokenSendInfo(src)).endCell());
        },
        parse: (src) => {
            return loadTokenSendInfo(src.loadRef().beginParse());
        }
    }
}
export async function distributeHandler(
    request: Request<{}, {}, DistributeDto>,
    response: Response<distributeResponse>,
    next: NextFunction
) {
    // Distribute
    try {

        //TODO
    

        // Response
        response.status(201).send({
            txUrl: "123"
        })

        } catch (error) {
            if (error instanceof Error){
                next(new HttpException(400, error.message))
            }
        }
    }

export async function distributeJettonHandler(
    request: Request<{}, {}, DistributeJettonDto>,
    response: Response<distributeResponse>,
    next: NextFunction
) {
    // Distribute
    try {
        const blockchain = await Blockchain.create();

        let message_dict = Dictionary.empty(Dictionary.Keys.BigUint(257), dictValueParserTokenSendInfo())
        let send_sum = 0;
        for (let i = 0; i < Object.keys(request.body.recipients).length; i++){
            const recipient = Object.keys(request.body.recipients)[i]
            const amount = request.body.recipients[recipient]
            message_dict.set(BigInt(i), {
                $$type: 'TokenSendInfo',
                recipient: address(recipient),
                value: toNano(amount),
            })
            send_sum += amount;
        }

        const payload = payload_body(address(request.body.jettonMasterAddress), BigInt(Object.keys(request.body.recipients).length), message_dict)

        const transferMessage: TokenTransfer = {
            $$type: "TokenTransfer",
            queryId: 0n,
            amount: toNano(send_sum),
            destination: address(request.body.contractAddress),
            response_destination: address(request.body.responseDestination),
            custom_payload: null,
            forward_ton_amount: toNano("0.05") * BigInt(Object.keys(request.body.recipients).length) + toNano('0.02') + (toNano("0.0086") * BigInt(Object.keys(request.body.recipients).length)),
            forward_payload: payload,
        };
        const body = beginCell().store(storeTokenTransfer2(transferMessage)).endCell();
        const sendValue = toNano("0.1") * BigInt(Object.keys(request.body.recipients).length) + toNano(1)
        const encodedBody = body.toBoc().toString('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
        // Response
        response.status(200).send({
            txUrl: `https://app.tonkeeper.com/transfer/${request.body.jettonWalletAddress}?bin=${encodedBody}&amount=${sendValue}`
        })

        } catch (error) {
            if (error instanceof Error){
                next(new HttpException(400, error.message))
            }
        }
    }
