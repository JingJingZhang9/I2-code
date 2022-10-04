import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import SB "mo:StableBuffer/StableBuffer";
import STMap "mo:StableTrieMap";

import ArchiveCanister "ArchiveCanister";
import T "Types";
import U "Utils";

module ICRC1 {
    public type StableTrieMap<K, V> = STMap.StableTrieMap<K, V>;
    public type StableBuffer<T> = SB.StableBuffer<T>;

    public type Account = T.Account;
    public type Subaccount = T.Subaccount;
    public type AccountStore = T.AccountStore;

    public type Transaction = T.Transaction;
    public type Balance = T.Balance;
    public type TransferArgs = T.TransferArgs;
    public type MintArgs = T.MintArgs;
    public type BurnArgs = T.BurnArgs;
    public type InternalTransferArgs = T.InternalTransferArgs;
    public type TransferError = T.TransferError;

    public type SupportedStandard = T.SupportedStandard;

    public type InitArgs = T.InitArgs;
    public type InternalData = T.InternalData;
    public type MetaDatum = T.MetaDatum;
    public type TxLog = T.TxLog;
    public type TxIndex = T.TxIndex;

    public type Interface = T.ICRC1_Interface;

    public type ArchiveInterface = T.ArchiveInterface;

    public type GetTransactionsRequest = T.GetTransactionsRequest;
    public type GetTransactionsResponse = T.GetTransactionsResponse;
    public type QueryArchiveFn = T.QueryArchiveFn;
    public type ArchivedTransaction = T.ArchivedTransaction;

    public let MAX_TRANSACTIONS_IN_LEDGER = 2000;
    public let MAX_TRANSACTION_BYTES : Nat64 = 85;

    /// Initialize a new ICRC-1 token
    public func init(args : InitArgs) : InternalData {
        let {
            name;
            symbol;
            decimals;
            fee;
            minting_account;
            max_supply;
        } = args;

        if (not U.validate_account(minting_account)) {
            Debug.trap("minting_account is invalid");
        };

        if (max_supply < 10 ** Nat8.toNat(decimals)) {
            Debug.trap("max_supply must be >= 1");
        };

        let accounts : AccountStore = STMap.new(Principal.equal, Principal.hash);
        STMap.put(
            accounts,
            minting_account.owner,
            U.new_subaccount_map(
                minting_account.subaccount,
                max_supply,
            ),
        );

        {
            name = name;
            symbol = symbol;
            decimals;
            var fee = fee;
            max_supply;
            minting_account;
            accounts;
            metadata = U.init_metadata(args);
            supported_standards = U.init_standards();
            transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            transaction_window = U.DAY_IN_NANO_SECONDS;
        };
    };

    public func name(token : InternalData) : Text {
        token.name;
    };

    public func symbol(token : InternalData) : Text {
        token.symbol;
    };

    public func decimals({ decimals } : InternalData) : Nat8 {
        decimals;
    };

    public func fee(token : InternalData) : Balance {
        token.fee;
    };

    public func metadata(token : InternalData) : [MetaDatum] {
        SB.toArray(token.metadata);
    };

    public func total_supply(token : InternalData) : Balance {
        let {
            max_supply;
            accounts;
            minting_account;
        } = token;

        max_supply - U.get_balance(accounts, minting_account);
    };

    public func minting_account(token : InternalData) : Account {
        token.minting_account;
    };

    public func balance_of({ accounts } : InternalData, req : Account) : Balance {
        U.get_balance(accounts, req);
    };

    public func supported_standards(token : InternalData) : [SupportedStandard] {
        SB.toArray(token.supported_standards);
    };

    public func mint(token : InternalData, args : MintArgs, caller : Principal) : Result.Result<Balance, TransferError> {

        if (not (caller == token.minting_account.owner)) {
            return #err(
                #GenericError {
                    error_code = 401;
                    message = "Unauthorized: Only the minting_account can mint tokens.";
                },
            );
        };

        let internal_args = {
            from = token.minting_account;
            to = args.to;
            amount = args.amount;
            fee = null;
            memo = args.memo;
            created_at_time = args.created_at_time;
        };

        switch (U.validate_transfer(token, internal_args)) {
            case (#err(errorType)) {
                return #err(errorType);
            };
            case (_) {};
        };

        U.transfer(token.accounts, internal_args);
        U.store_tx(token, internal_args, #mint);

        #ok(internal_args.amount);
    };

    public func burn(token : InternalData, args : BurnArgs, caller : Principal) : Result.Result<Balance, TransferError> {

        let internal_args = {
            from = {
                owner = caller;
                subaccount = args.from_subaccount;
            };
            to = token.minting_account;
            amount = args.amount;
            fee = null;
            memo = args.memo;
            created_at_time = args.created_at_time;
        };

        switch (U.validate_transfer(token, internal_args)) {
            case (#err(errorType)) {
                return #err(errorType);
            };
            case (_) {};
        };

        U.transfer(token.accounts, internal_args);
        U.store_tx(token, internal_args, #burn);

        #ok(internal_args.amount);
    };

    public func transfer(
        token : InternalData,
        args : TransferArgs,
        caller : Principal,
    ) : Result.Result<Balance, TransferError> {
        let {
            accounts;
            minting_account;
            transaction_window;
        } = token;

        let internal_args = U.transfer_args_to_internal(args, caller);

        let { from; to } = internal_args;

        if (from == minting_account or to == minting_account) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "minting_account can only participate in minting and burning transactions not transfers";
                }),
            );
        };

        switch (args.fee) {
            case (?fee) {
                if (not (token.fee == fee)) {
                    return #err(
                        #BadFee {
                            expected_fee = token.fee;
                        },
                    );
                };
            };
            case (_) {
                if (not (token.fee == 0)) {
                    return #err(
                        #BadFee {
                            expected_fee = token.fee;
                        },
                    );
                };
            };
        };

        switch (U.validate_transfer(token, internal_args)) {
            case (#err(errorType)) {
                return #err(errorType);
            };
            case (#ok(_)) {};
        };

        U.transfer(token.accounts, internal_args);
        U.store_tx(token, internal_args, #transfer);

        #ok(internal_args.amount);
    };

    public func get_transaction(token : InternalData, tx_index : Nat) : ?Transaction {
        SB.getOpt(token.transactions, tx_index);
    };

    public func get_transactions(
        token : InternalData,
        req : GetTransactionsRequest,
    ) : [Transaction] {
        let tx_index = req.start;

        if (SB.size(token.transactions) < tx_index) {
            Array.tabulate<Transaction>(
                Int.abs(SB.size(token.transactions) - tx_index - 1),
                func(i : Nat) : Transaction {
                    SB.get(token.transactions, i);
                },
            );
        } else {
            [];
        };
    };

    public func a() : async () {
        let a : ArchiveInterface = await ArchiveCanister.ArchiveCanister({
            max_memory_size_bytes = 45;
        });

    };
};