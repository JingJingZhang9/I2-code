# ICRC1/Types

## Type `Value`
``` motoko no-repl
type Value = {#Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text}
```


## Type `BlockIndex`
``` motoko no-repl
type BlockIndex = Nat
```


## Type `Subaccount`
``` motoko no-repl
type Subaccount = Blob
```


## Type `Balance`
``` motoko no-repl
type Balance = Nat
```


## Type `StableBuffer`
``` motoko no-repl
type StableBuffer<T> = StableBuffer.StableBuffer<T>
```


## Type `StableTrieMap`
``` motoko no-repl
type StableTrieMap<K, V> = STMap.StableTrieMap<K, V>
```


## Type `Account`
``` motoko no-repl
type Account = { owner : Principal; subaccount : ?Subaccount }
```


## Type `EncodedAccount`
``` motoko no-repl
type EncodedAccount = Blob
```


## Type `SupportedStandard`
``` motoko no-repl
type SupportedStandard = { name : Text; url : Text }
```


## Type `Memo`
``` motoko no-repl
type Memo = Blob
```


## Type `Timestamp`
``` motoko no-repl
type Timestamp = Nat64
```


## Type `Duration`
``` motoko no-repl
type Duration = Nat64
```


## Type `TxIndex`
``` motoko no-repl
type TxIndex = Nat
```


## Type `TxLog`
``` motoko no-repl
type TxLog = StableBuffer<Transaction>
```


## Type `MetaDatum`
``` motoko no-repl
type MetaDatum = (Text, Value)
```


## Type `MetaData`
``` motoko no-repl
type MetaData = [MetaDatum]
```


## Type `OperationKind`
``` motoko no-repl
type OperationKind = {#mint; #burn; #transfer}
```


## Type `Mint`
``` motoko no-repl
type Mint = { to : Account; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `BurnArgs`
``` motoko no-repl
type BurnArgs = { from_subaccount : ?Subaccount; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `Burn`
``` motoko no-repl
type Burn = { from : Account; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `TransferArgs`
``` motoko no-repl
type TransferArgs = { from_subaccount : ?Subaccount; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `Transfer`
``` motoko no-repl
type Transfer = { from : Account; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `Operation`
``` motoko no-repl
type Operation = {#mint : Mint; #burn : Burn; #transfer : Transfer}
```


## Type `TransactionRequest`
``` motoko no-repl
type TransactionRequest = { kind : OperationKind; from : Account; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64; encoded : { from : EncodedAccount; to : EncodedAccount } }
```


## Type `Transaction`
``` motoko no-repl
type Transaction = { kind : Text; mint : ?Mint; burn : ?Burn; transfer : ?Transfer; timestamp : Timestamp }
```

Max size
kind : 8 chars (8 * 32 /8) -> 32
from : (32 + 32) -> 68 B
to : 68  B
fee : Nat64 -> 8 B
amount : Nat128 -> 16 B
memo: 32 -> 4 B
time : Nat64 -> 8 B
---------------------------
total : 196 Bytes

## Type `TimeError`
``` motoko no-repl
type TimeError = {#TooOld; #CreatedInFuture : { ledger_time : Timestamp }}
```


## Type `TransferError`
``` motoko no-repl
type TransferError = TimeError or {#BadFee : { expected_fee : Balance }; #BadBurn : { min_burn_amount : Balance }; #InsufficientFunds : { balance : Balance }; #Duplicate : { duplicate_of : TxIndex }; #TemporarilyUnavailable; #GenericError : { error_code : Nat; message : Text }}
```


## Type `TokenInterface`
``` motoko no-repl
type TokenInterface = actor { icrc1_name : shared query () -> async Text; icrc1_symbol : shared query () -> async Text; icrc1_decimals : shared query () -> async Nat8; icrc1_fee : shared query () -> async Balance; icrc1_metadata : shared query () -> async MetaData; icrc1_total_supply : shared query () -> async Balance; icrc1_minting_account : shared query () -> async ?Account; icrc1_balance_of : shared query (Account) -> async Balance; icrc1_transfer : shared (TransferArgs) -> async Result.Result<Balance, TransferError>; icrc1_supported_standards : shared query () -> async [SupportedStandard] }
```

Interface for the ICRC token canister

## Type `TxCandidBlob`
``` motoko no-repl
type TxCandidBlob = Blob
```


## Type `ArchiveInterface`
``` motoko no-repl
type ArchiveInterface = actor { append_transactions : shared ([Transaction]) -> async Result.Result<(), Text>; total_transactions : shared query () -> async Nat; get_transaction : shared query (TxIndex) -> async ?Transaction; get_transactions : shared query (GetTransactionsRequest) -> async [Transaction]; remaining_capacity : shared query () -> async Nat }
```


## Type `InitArgs`
``` motoko no-repl
type InitArgs = { name : Text; symbol : Text; decimals : Nat8; fee : Balance; minting_account : Account; max_supply : Balance; transaction_window : ?Time.Time; initial_balances : [(Account, Balance)] }
```


## Type `ExportedArgs`
``` motoko no-repl
type ExportedArgs = InitArgs and { transaction_window : ?Timestamp; minting_account : ?Account; metadata : ?MetaData; supported_standards : ?[SupportedStandard]; accounts : ?[(Principal, [(Subaccount, Balance)])]; transactions : ?[Transaction] }
```


## Type `AccountStore`
``` motoko no-repl
type AccountStore = StableTrieMap<EncodedAccount, Balance>
```


## Type `TransactionRange`
``` motoko no-repl
type TransactionRange = { start : TxIndex; length : Nat }
```


## Type `ArchiveData`
``` motoko no-repl
type ArchiveData = { canister : ArchiveInterface } and TransactionRange
```


## Type `TokenData`
``` motoko no-repl
type TokenData = { name : Text; symbol : Text; decimals : Nat8; var fee : Balance; max_supply : Balance; minting_account : Account; accounts : AccountStore; metadata : StableBuffer<MetaDatum>; supported_standards : StableBuffer<SupportedStandard>; transaction_window : Nat; permitted_drift : Nat; transactions : StableBuffer<Transaction>; archives : StableBuffer<ArchiveData> }
```


## Type `GetTransactionsRequest`
``` motoko no-repl
type GetTransactionsRequest = TransactionRange
```

A prefix array of the transaction range specified in the [GetTransactionsRequest](./#GetTransactionsRequest) request.

## Type `QueryArchiveFn`
``` motoko no-repl
type QueryArchiveFn = (GetTransactionsRequest) -> async ([Transaction])
```


## Type `ArchivedTransaction`
``` motoko no-repl
type ArchivedTransaction = { start : TxIndex; length : Nat }
```


## Type `GetTransactionsResponse`
``` motoko no-repl
type GetTransactionsResponse = { log_length : Nat; first_index : TxIndex; transactions : [Transaction]; archived_transactions : [ArchivedTransaction] }
```
