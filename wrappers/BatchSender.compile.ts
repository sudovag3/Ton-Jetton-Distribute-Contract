import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/batch_sender.tact',
    options: {
        debug: true,
    },
};
