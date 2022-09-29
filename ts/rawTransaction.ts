import dotenv from "dotenv";
dotenv.config();

import { AptosClient, AptosAccount, FaucetClient, BCS, TxnBuilderTypes } from "aptos";
import {NODE_URL, FAUCET_URL, aptosCoinStore} from"./common";
import { TransactionBuilder,TransactionBuilderEd25519, SigningFn,TransactionBuilderABI, CoinClient } from "aptos";
import { TransactionPayload_EntryFunctionPayload } from "aptos/src/generated";

import assert from "assert";
const {
    AccountAddress,
    TypeTagStruct,
    EntryFunction,
    StructTag,
    TransactionPayloadEntryFunction,
    RawTransaction,
    ChainId,
  } = TxnBuilderTypes;


function signAndSendTransaction(
    publicKey ,
    deploy,
    signature,
    nodeAddress,
){
    const client = new AptosClient(nodeAddress)
}  
function createUnsignMintTransaction(
    entryFunction,
    args
){
    let adminAddress = "0x2bb51436741c2470608fa2f2f09e3a322a3014ce03a34f3b809b8494619e5712"
    let mpcAddress = 0x2bb51436741c2470608fa2f2f09e3a322a3014ce03a34f3b809b8494619e5712
    const account2 = new AptosAccount();

    // Create unsign deploy here
    const payload: TransactionPayload_EntryFunctionPayload = {
        type: "entry_function_payload",
        function: `${adminAddress}::aCoin::${entryFunction}`,
        type_arguments: [],
        arguments: args,
      };
      const txnRequest = await client.generateTransaction(account1.address(), payload, { max_gas_amount: "2000" });
      const signedTxn = await client.signTransaction(account1, txnRequest);
      const transactionRes = await client.submitTransaction(signedTxn);
      const txn = await client.waitForTransactionWithResult(transactionRes.hash);
      expect((txn as any)?.success).toBe(true);
  
      resources = await client.getAccountResources(account2.address());
      accountResource = resources.find((r) => r.type === aptosCoin);
      expect((accountResource!.data as { coin: { value: string } }).coin.value).toBe("717");
  
      const res = await client.getAccountTransactions(account1.address(), { start: BigInt(0) });
      const tx = res.find((e) => e.type === "user_transaction") as Gen.UserTransaction;
      expect(new HexString(tx.sender).toShortString()).toBe(account1.address().toShortString());
  
      const events = await client.getEventsByEventHandle(tx.sender, aptosCoin, "withdraw_events");
      expect(events[0].type).toBe("0x1::coin::WithdrawEvent");
  
      const eventSubset = await client.getEventsByEventHandle(tx.sender, aptosCoin, "withdraw_events", {
        start: BigInt(0),
        limit: 1,
      });
      expect(eventSubset[0].type).toBe("0x1::coin::WithdrawEvent");
  
      const events2 = await client.getEventsByCreationNumber(
        events[0].guid.account_address,
        events[0].guid.creation_number,
      );
      expect(events2[0].type).toBe("0x1::coin::WithdrawEvent");
    },
    30 * 1000,
  
  
    
}