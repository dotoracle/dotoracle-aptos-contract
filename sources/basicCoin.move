
module admin::aCoin {
    use std::signer;
    //use std::string;
    use std::string::utf8;
    use std::string;
    //use std::error;
    //use std::option;
    //use aptos_std::type_info;
    //use aptos_framework::optional_aggregator;
    //use aptos_framework::account;
    use aptos_framework::coin;
    //use aptos_framework::managed_coin;

    /// ERROR CODE
    const ENO_CAPABILITIES: u64 = 1;
    const ERR_NOT_ADMIN_TO_MINT:u64 =2;
    const ERR_AMOUNT_EQUAL_TO_0 : u64 = 3;
    const ERR_INSUFFIENCENT_BALANCE_TO_BRIDGE_BACK: u64 = 4;


    struct MyCoin {}

    // struct Coin<phantom CoinType> has store {
    //     /// Amount of coin this address has.
    //     value: u64,
    // }

    struct Capabilities<phantom CoinType> has key {
        burn_cap: coin::BurnCapability<CoinType>,
        freeze_cap: coin::FreezeCapability<CoinType>,
        mint_cap: coin::MintCapability<CoinType>,
    }

    // struct CoinInfo<phantom CoinType> has key {
    //     name: string::String,
    //     /// Symbol of the coin, usually a shorter version of the name.
    //     /// For example, Singapore Dollar is SGD.
    //     symbol: string::String,
    //     /// Number of decimals used to get its user representation.
    //     /// For example, if `decimals` equals `2`, a balance of `505` coins should
    //     /// be displayed to a user as `5.05` (`505 / 10 ** 2`).
    //     decimals: u8,
    //     /// Amount of this coin type in existence.
    //     supply: option::Option<optional_aggregator::OptionalAggregator>,
    // }


    public entry fun initialize(account: &signer) {
         
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MyCoin>(
            account,
            utf8(b"mycoin"),
            utf8(b"MC"),
            6,
            true,
        );

        let coins = coin::mint(88888, &mint_cap); // 10^12
        coin::register<MyCoin>(account);
        coin::deposit(signer::address_of(account), coins);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_mint_cap(mint_cap);
    }


    // public fun coin_address_1<CoinType>(): address {
    //     let type_info = type_info::type_of<CoinType>();
    //     type_info::account_address(&type_info)
    // }

    
    // public fun mint_internal<MyCoin>(
    // ) {
    // }


    // Only admin = MPC can mint token
    public entry fun mint(admin_account: &signer, to: address, amount: u64) acquires Capabilities {
        let admin_addr = signer::address_of(admin_account);
        assert!( admin_addr== @admin, ERR_NOT_ADMIN_TO_MINT);
        assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);

        let capabilities = borrow_global<Capabilities<MyCoin>>(admin_addr);

        let coins = coin::mint(amount, &capabilities.mint_cap); // 10^12
        //coin::register<MyCoin>(to);
        coin::deposit(to, coins);

        coin::destroy_burn_cap(capabilities.burn_cap);
        coin::destroy_freeze_cap(capabilities.freeze_cap);
        coin::destroy_mint_cap(capabilities.mint_cap);
    }

    // Receiver must call this function before MPC can mint
    public entry fun request_to_mint(request_account: &signer, amount: u64) {
        assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);
        coin::register<MyCoin>(request_account);     
    }

    public entry fun request_bridge_back<MyCoin>(
        request_account: &signer, 
        to: string::String, 
        amount: u64, 
        to_chain_id: u128, 
        request_id: string::String ) acquires Capabilities
        
        {
            let request_addr = signer::address_of(request_account);
            assert!(amount>0, ERR_AMOUNT_EQUAL_TO_0);
            // check if balance is not enough to bridge
            assert!(coin::balance<MyCoin>(request_addr) >= amount, ERR_INSUFFIENCENT_BALANCE_TO_BRIDGE_BACK);
            // TODO: check to_chain_id 
            // TODO: check format of request_id
            // TODO: check UNIQUE request_id
            let capabilities = borrow_global_mut<Capabilities<MyCoin>>(request_addr);
            // burn coin
            coin::burn_from(request_addr, amount, &capabilities.burn_cap)
        }
    
}