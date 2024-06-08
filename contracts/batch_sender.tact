import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./imports/stdlib1.fc";


// C̲o̲n̲s̲t̲a̲n̲t̲s̲
const SEND_TON_COST: Int = ton("0.000309");
const SEND_TON_PROCESS: Int = ton("0.01");
const MINIMAL_CONTRACT_BALANCE: Int = ton("0.01");
const RESEND_VALUE: Int = ton("0.15");
const NOT_ENOUGTH_VALUE: Int = 1001;
//____________________________________________________________

// S̲t̲r̲u̲c̲t̲s̲ a̲n̲d̲ m̲e̲t̲h̲o̲d̲s̲ f̲r̲o̲m̲ F̲u̲n̲C̲
@name(store_dict)
extends native storeDict(self: Builder, c: Cell): Builder;
struct DictLoadRes{
    slice: Slice;
    dict: Cell;
}

@name(load_dict)
extends native loadDict(self: Slice): DictLoadRes;
struct DictGetRes{
    slice: Slice;
    success: Int;
}

struct DictGetMinRes{
    key: Int;
    slice: Slice;
    success: Int;
}

struct DictGetNextRes{
    key: Int;
    slice: Slice;
    success: Int;
}

struct TokenSendInfo {
    recipient: Address;
    value: Int;
}

@name(udict_get?)
extends native udictGet(self: Cell, kl: Int, k: Int): DictGetRes;

@name(idict_get_min?)
extends native idictGetMin(self: Cell, kl: Int): DictGetNextRes;

@name(idict_get_next?)
extends native idictGetNext(self: Cell, kl: Int, p: Int): DictGetNextRes;
//____________________________________________________________

// M̲e̲s̲s̲a̲g̲e̲s̲
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}


message TokenSend {
    length: Int as uint64;
    tokenRoot: Address;
    sendInfo: map<Int, TokenSendInfo>;
}

message SetSendCost {
    send_cost: Int;
}

message Send {
    queryId: Int as uint64;
    length: Int as uint64;
    sum: Int;
    sendInfo: map<Int, TokenSendInfo>;
    cursor: Int;
}

//____________________________________________________________


contract BatchSender with Deployable, Ownable, OwnableTransferable, Stoppable, Resumable {
    id: Int as uint32;
    send_cost: Int;
    owner: Address;
    stopped: Bool;

    init(id: Int, send_cost: Int) {
        self.owner = sender();
        self.stopped = false;
        self.id = id;
        self.send_cost = send_cost;
    }

    // Method for sending native TON to different senders
    receive(msg: Send) {
        let ctx: Context = context();
        
        //Reserve balance on Contract to avoid freeze
        nativeReserve(max(
            MINIMAL_CONTRACT_BALANCE,
            myBalance() - ctx.value
        ), 0);
    

        
        let hasMore: Bool = true;
        let needBreak: Bool = false;
        let cursorStart: Int = msg.cursor;
        // Go through the array of recipients in a loop and send TON
        do {              
            if ((msg.sendInfo.get(msg.cursor)!!).value != 0) {
            send(SendParameters{
                to: (msg.sendInfo.get(msg.cursor)!!).recipient,
                value: SEND_TON_COST + (msg.sendInfo.get(msg.cursor)!!).value,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false
            });
            }
            msg.cursor = msg.cursor + 1;
        
            if (msg.sendInfo.get(msg.cursor) == null){
                hasMore = false;
                needBreak = true;
            }

            if (msg.cursor - cursorStart > 120) {
                needBreak = true;
            }
        } until (needBreak);

        if (hasMore){
            send(SendParameters{
                to: myAddress(),
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: msg.toCell()
            });
            msg.sendInfo = emptyMap();
        }
    }

    //Method for manually withdrawing all TONs to the owner’s address
    receive("withdraw"){
        self.requireOwner();
        nativeReserve(
            MINIMAL_CONTRACT_BALANCE
        , 0);

        send(SendParameters
        {
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false
        });
    }


    receive(msg: TokenNotification) {
        let ctx: Context = context();

        nativeReserve(max(
            MINIMAL_CONTRACT_BALANCE,
            myBalance() - ctx.value
        ), 0);
    
        let meta_data: Slice = msg.forward_payload.loadRef().beginParse();
       
        let length: Int = meta_data.loadUint(64);
        let from: Address = meta_data.loadAddress();

        let sendersContent: Slice = msg.forward_payload.loadRef().beginParse();
        
        nativeThrowUnless(905, sendersContent.loadUint(8) == 0);
        let contDict: DictLoadRes = sendersContent.loadDict();  
        
        nativeThrowUnless(906, contDict.dict != null);
        
        let sendInfo: DictGetNextRes = contDict.dict.idictGetMin(257);
        nativeThrowUnless(907, sendInfo.success == -1);
        
        repeat(length){

            let SendInfoSlice: Slice = sendInfo.slice.loadRef().beginParse();
            
            let recipient: Address = SendInfoSlice.loadAddress();
            let amount: Int = SendInfoSlice.loadInt(257);

            send(SendParameters{
                to: sender(),
                value: self.send_cost,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                body: beginCell().storeUint(0xf8a7ea5, 32).storeUint(msg.queryId, 64).storeCoins(amount).storeSlice(recipient.asSlice()).storeSlice(self.owner.asSlice()).storeUint(0, 1).storeCoins(0).storeUint(0, 1).endCell()
            });

            sendInfo = contDict.dict.idictGetNext(257, sendInfo.key);
            
        }

        send(
            SendParameters{
                to: msg.from,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "Finish".asComment()
            }
        );


    }

    receive(msg: SetSendCost) {
        self.requireOwner();
        self.send_cost = msg.send_cost;

        nativeReserve(
            MINIMAL_CONTRACT_BALANCE
        , 0);

        send(SendParameters
        {
            to: sender(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false
        });
    }


    get fun id(): Int {
        return self.id;
    }

    get fun sendCost(): Int {
        return self.send_cost;
    }
    
    get fun buildTokenSendPayload(msg: TokenSend): Cell {
        return beginCell().storeRef(
           beginCell().
           storeUint(msg.length, 64). // 
           storeAddress(msg.tokenRoot).
           endCell()
        ).storeRef(beginCell().storeUint(0,8).storeDict(msg.sendInfo.asCell()!!).endCell()).endCell();
    }

    get fun fullTonSendAddiction(length: Int): Int {
        return length * (SEND_TON_PROCESS) + (length / 120) * RESEND_VALUE;
    }

}