
module admin::basicCoin {
    use std::signer;
    use std::string::utf8;
    use std::error;

    use aptos_framework::coin;

    /// ERROR CODE
    const ENO_CAPABILITIES: u64 = 1;


    struct MyCoin {}
    struct Capabilities<phantom CoinType> has key {
        burn_cap: coin::BurnCapability<CoinType>,
        freeze_cap: coin::FreezeCapability<CoinType>,
        mint_cap: coin::MintCapability<CoinType>,
    }

    public entry fun initialize(account: &signer) {
         
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MyCoin>(
            account,
            utf8(b"mycoin"),
            utf8(b"MC"),
            6,
            true,
        );

        let coins = coin::mint(5555555, &mint_cap); // 10^12
        coin::register<MyCoin>(account);
        coin::deposit(signer::address_of(account), coins);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_mint_cap(mint_cap);
    }

     /// Create new coins `CoinType` and deposit them into dst_addr's account.
    public fun mint_internal<MyCoin>(
        account: &signer,
        dst_addr: address,
        amount: u64,
    ) acquires Capabilities {
        let account_addr = signer::address_of(account);

        assert!(
            exists<Capabilities<MyCoin>>(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let capabilities = borrow_global<Capabilities<MyCoin>>(account_addr);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(dst_addr, coins_minted);
    }

    public entry fun mint<MyCoin>(account: &signer, to: address, amount: u64) acquires Capabilities {
       // assert!(get_max_supply() >= ((option::destroy_some(coin::supply<MyCoin>()) as u64) + amount), ERR_TOO_BIG_AMOUNT);
        mint_internal<MyCoin>(account, to, amount);
    }
    // public entry fun request_bridge_back<MyCoin>(account: &signer, to: address, amount: u64) {

    // }
    
}