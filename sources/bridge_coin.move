
module dotoracle::bridge_coin {
    use std::signer;
    //use std::string;
    use std::string:: {String};
    use std::table;
    use std::vector;
    use std::secp256k1;
    use std::option;
    use aptos_framework::account;
    //use std::error;
    //use std::option;
    //use aptos_std::type_info;
    //use aptos_framework::optional_aggregator;
    use aptos_framework::coin;
    //use aptos_framework::managed_coin;

    const FEE_DIVISOR: u64 = 10000;

    /// ERROR CODE
    const ENO_CAPABILITIES: u64 = 1;
    const ERR_NOT_ADMIN_TO_MINT:u64 =2;
    const ERR_AMOUNT_EQUAL_TO_0 : u64 = 3;
    const ERR_INSUFFIENCENT_BALANCE_TO_BRIDGE_BACK: u64 = 4;
    const ERR_INSUFFICIENT_PERMISSION: u64 = 5;
    const ERR_COIN_EXIST: u64 = 6;
    const ERR_CONTRACT_INITIALIZED: u64 = 6;

    struct BridgeCoin<phantom CoinType> has key {
        origin_chain_id: u128,
        origin_contract_address: String,
        index: u128,
        claimed_ids: table::Table<String, bool>,
        requests: table::Table<String, bool>,
        burn_cap: coin::BurnCapability<CoinType>,
        freeze_cap: coin::FreezeCapability<CoinType>,
        mint_cap: coin::MintCapability<CoinType>,
        bridge_fee: u64
    }

    struct MPCWallet has key {
        mpc_pubkey: vector<u8>
    }

    fun assert_mpc_initialized() {
        assert!(exists<MPCWallet>(@dotoracle), ERR_CONTRACT_INITIALIZED);
    }

    public entry fun initialize(account: &signer, mpc_pubkey: vector<u8>) {
        let sender = signer::address_of(account);
        assert!(sender == @dotoracle, ERR_INSUFFICIENT_PERMISSION);
        assert!(vector::length(&mpc_pubkey) == 64, ERR_INSUFFICIENT_PERMISSION);
        assert!(!exists<MPCWallet>(@dotoracle), ERR_CONTRACT_INITIALIZED);
        move_to(account, MPCWallet { mpc_pubkey })
    }

    public entry fun register_coin<CoinType>(account: &signer, origin_chain_id: u128, origin_contract_address: String, name: String, symbol: String, decimal: u8) {
        let sender = signer::address_of(account);
        assert!(sender == @dotoracle, ERR_INSUFFICIENT_PERMISSION);
        assert!(!exists<BridgeCoin<CoinType>>(@dotoracle), ERR_COIN_EXIST);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            account,
            name,
            symbol,
            decimal,
            true,
        );

        move_to(account, BridgeCoin<CoinType> {
            origin_chain_id,
            origin_contract_address,
            index: 0,
            claimed_ids: table::new(),
            requests: table::new(),
            burn_cap: burn_cap,
            freeze_cap: freeze_cap,
            mint_cap: mint_cap,
            bridge_fee: 0
        })
    }

    public fun is_signature_valid(message: vector<u8>, recovery_id: u8, signature: vector<u8>): bool acquires MPCWallet {
        assert_mpc_initialized();
        let mpc_pubkey = borrow_global<MPCWallet>(@dotoracle).mpc_pubkey;

        if (vector::length(&signature) != 64) {
            return false
        };

        let ecdsa_signature = secp256k1::ecdsa_signature_from_bytes(signature);
        let recovered_public_key_option = secp256k1::ecdsa_recover(message, recovery_id, &ecdsa_signature);
        if (option::is_none(&recovered_public_key_option)) {
            return false
        };
        let recovered_public_key = option::extract(&mut recovered_public_key_option);
        let public_key_bytes = secp256k1::ecdsa_raw_public_key_to_bytes(&recovered_public_key);
        public_key_bytes == mpc_pubkey
    }


    // public fun coin_address_1<CoinType>(): address {
    //     let type_info = type_info::type_of<CoinType>();
    //     type_info::account_address(&type_info)
    // }

    
    // public fun mint_internal<MyCoin>(
    // ) {
    // }


    // Only admin = MPC can mint token
    // public entry fun mint(admin_account: &signer, to: address, amount: u64) acquires Capabilities {
    //     let admin_addr = signer::address_of(admin_account);
    //     assert!( admin_addr== @admin, ERR_NOT_ADMIN_TO_MINT);
    //     assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);

    //     let capabilities = borrow_global<Capabilities<MyCoin>>(admin_addr);

    //     let coins = coin::mint(amount, &capabilities.mint_cap); // 10^12
    //     //coin::register<MyCoin>(to);
    //     coin::deposit(to, coins);

    //     coin::destroy_burn_cap(capabilities.burn_cap);
    //     coin::destroy_freeze_cap(capabilities.freeze_cap);
    //     coin::destroy_mint_cap(capabilities.mint_cap);
    // }

    // // Receiver must call this function before MPC can mint
    // public entry fun request_to_mint(request_account: &signer, amount: u64) {
    //     assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);
    //     coin::register<MyCoin>(request_account);     
    // }

    // public entry fun request_bridge_back<MyCoin>(
    //     request_account: &signer, 
    //     to: string::String, 
    //     amount: u64, 
    //     to_chain_id: u128, 
    //     request_id: string::String ) acquires Capabilities
        
    //     {
    //         let request_addr = signer::address_of(request_account);
    //         assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);
    //         // check if balance is not enough to bridge
    //         assert!(coin::balance<MyCoin>(request_addr) >= amount, ERR_INSUFFIENCENT_BALANCE_TO_BRIDGE_BACK);
    //         // TODO: check to_chain_id 
    //         // TODO: check format of request_id
    //         // TODO: check UNIQUE request_id
    //         let capabilities = borrow_global_mut<Capabilities<MyCoin>>(request_addr);
    //         // burn coin
    //         coin::burn_from(request_addr, amount, &capabilities.burn_cap)
    //     }
    
    #[test]
    fun test_verify_signature() acquires MPCWallet {
        use std::hash;
        let dotoracle_signer = account::create_account_for_test(@dotoracle);
        initialize(&dotoracle_signer, x"4646ae5047316b4230d0086c8acec687f00b1cd9d1dc634f6cb358ac0a9a8ffffe77b4dd0a4bfb95851f3b7355c781dd60f8418fc8a65d14907aff47c903a559");
        assert!(is_signature_valid(
            hash::sha2_256(b"test aptos secp256k1"),
            0,
            x"f7ad936da03f948c14c542020e3c5f4e02aaacd1f20427c11aa6e2fbf8776477646bba0e1a37f9e7c777c423a1d2849baafd7ff6a9930814a43c3f80d59db56f"
        ), 2)
    }
}