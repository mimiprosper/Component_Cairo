// Ownable Component. This is a component that implements the IOwnable trait
use starknet::{ContractAddress, get_caller_address};

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn owner(self: @TContractState) -> ContractAddress;
    fn renounce_ownership(ref self: TContractState);
}

// Error messages
pub mod Errors {
    pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be address zero';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be address zero';
    pub const NOT_OWNER: felt252 = 'Caller not owner';
}

// use this attribute to decorate a component
#[starknet::component] 
pub mod ownable_component {
    use super::IOwnable;
    // import contract address & caller address modules
    use super::{
        ContractAddress, get_caller_address
    }; 
    // import modules for working with is.zero()
    use core::num::traits::Zero; 
    // import errors messages
    use super::Errors;

    // storage stores the owner
    #[storage] 
    struct Storage {
        owner: ContractAddress,
    }

    // event that would emit ownership has been transferred
    #[event] 
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    // ownerShipTransferred struct
    struct OwnershipTransferred { 
        previous_owner: ContractAddress,
        new_owner: ContractAddress
    }

    // Ownable Implementation. External interaction of the component
    // This makes it publically accessible to external contracts
    #[embeddable_as(Ownable)]
    impl OwnableImpl<
        TContractState, +HasComponent<TContractState>
    > of IOwnable<ComponentState<TContractState>> {
        // This function reads the state to get the owner
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        // This transfers ownership from previous owner to a new owner.
        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            // ensure new owner is NOT address zero
            assert(
                !new_owner.is_zero(), Errors::ZERO_ADDRESS_CALLER
            ); 
            // implementing internal function, assert_only_owner
            self.assert_only_owner(); 
            // implemting the internal function, _transfer_ownership
            self
                ._transfer_ownership(
                    new_owner
                ); 
        }
        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            // implementing internal function, assert_only_owner
            self.assert_only_owner(); 
            // implementing the internal function, _transfer_ownership
            self
                ._transfer_ownership(
                    Zero::zero()
                ); 
        }
    }

    // This is for the internal implementation of the component
    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }
        // the function transfers ownership from previous owner to new owner
        fn _transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            // get the previous owner
            let previous_owner: ContractAddress = self.owner.read(); 
           // writes the new owner to the state
            self.owner.write(new_owner); 
            //emits OwnershipTransferred events
            self
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                ); 
        }
        // this function strictly ensures that ony the owner has rights
        fn assert_only_owner(self: @ComponentState<TContractState>) {
            // get owner contract address
            let owner: ContractAddress = self.owner.read(); 
             // gets caller address
            let caller: ContractAddress = get_caller_address();
            //ensures caller is the owner
            assert(caller == owner, Errors::NOT_OWNER); 
            // ensures caller is not address zero
            assert(
                !caller.is_zero(), Errors::ZERO_ADDRESS_OWNER
            );
        }
    }
}
