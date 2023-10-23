# modclub_example

The modclub_example project The modclub_example project is to demonstrate how modclub sdk can be integrated with any canister to start sending the content for moderation.

# Set up Modclub

For the very first time, modclub can be setup by calling the below command:

To send content to Modclub's dev environment:
dfx canister call provider_app initModclubProvider

To topUp provider account on Modclub platform:
dfx canister call provider_app topUpProviderAccount '(100_000_000 : nat)'

To send content to Modclub's prod environment:
dfx canister call provider_app submitContentToModclub