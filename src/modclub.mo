import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Principal "mo:base/Principal";


// This is the interface to modclub for providers
module {

  type ContentId = Text;
  public type ContentStatus = {
    #approved;
    #rejected;
    #new;
  };

  public type ViolatedRules = {
    id : Text;
    rejectionCount: Nat;
  };

  public type ContentResult = {
    sourceId : Text;
    approvedCount: Nat;
    rejectedCount: Nat;
    status : ContentStatus;
    violatedRules: [ViolatedRules];
  };

  public type ProviderSettings = {
    requiredVotes: Nat;
    minStaked: Nat;
  };

  public type Image = {
    data: [Nat8];
    imageType: Text;
  };

  public type SubscribeMessage = { callback: shared ContentResult -> (); };

  public type PohVerificationStatus = {
    #startPoh;
    #notSubmitted;
    #pending;
    #verified;
    #rejected;
    #expired;
  };

  public type PohVerificationResponsePlus = {
    providerUserId: Text;
    status: PohVerificationStatus;
    // status at each challenge level
    challenges: [ChallengeResponse];
    providerId: Principal;
    token: ?Text;
    rejectionReasons: [Text];
    requestedAt: ?Int;
    submittedAt: ?Int;
    completedAt: ?Int;
    isFirstAssociation: Bool;
  };

  public type SubscribePohMessage = {
    callback: shared (PohVerificationResponsePlus) -> ();
  };

  public type ChallengeResponse = {
    challengeId: Text;
    status : PohChallengeStatus;
    completedOn : ?Int;
  };

  public type PohChallengeStatus = {#notSubmitted; #pending; #verified; #rejected; #expired;};

  public type PohUniqueToken =  {
    token: Text;
  };

  public type Rule = {
    id: Text;
    description: Text;
  };

  public type Level = {
    #simple;
    #normal;
    #hard;
    #xhard;
  };

  public type Result<T, E> = { #Ok : T; #Err : E };
  public type Account = { owner : Principal; subaccount : ?Subaccount };
  public type Subaccount = Blob;
  public type Tokens = Nat;
  public type Memo = Blob;
  public type Timestamp = Nat64;
  public type TxIndex = Nat;
  public type DeduplicationError = {
    #TooOld;
    #Duplicate : { duplicate_of : TxIndex };
    #CreatedInFuture : { ledger_time : Timestamp };
  };
  public type CommonError = {
    #InsufficientFunds : { balance : Tokens };
    #BadFee : { expected_fee : Tokens };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };
  public type TransferError = DeduplicationError or CommonError or {
    #BadBurn : { min_burn_amount : Tokens };
  };

  public type ModclubActorType = actor {
    registerProvider: (Text, Text, ?Image) -> async Text;
    deregisterProvider: () -> async Text;
    addRules: ([Text], ?Principal) -> async ();
    getProviderRules: () -> async [Rule];
    removeRules: ([Text], ?Principal) -> async ();
    addProviderAdmin:(Principal, Text, ?Principal) -> async ();
    removeProviderAdmin: (Principal, Principal) -> async ();
    submitText: (Text, Text, ?Text, ?Level) -> async Text;
    submitImage: (Text, [Nat8], Text, ?Text, ?Level) -> async Text;
    submitHtmlContent: (Text, Text, ?Text, ?Level) -> async Text;
    subscribe: (SubscribeMessage) -> async ();
    // Provider funds management
    getProviderSa(Text, ?Principal) : async Blob;
    providerSaBalance(Text, ?Principal) : async Tokens;
    // Proof of Humanity APIs
    verifyHumanity: (Text) -> async PohVerificationResponsePlus;
    subscribePohCallback: (SubscribePohMessage) -> async ();
  };

  public type ModclubLedgerActorType = actor {
    icrc1_balance_of : (Account) -> async Tokens;
    icrc1_fee : () -> async Nat;
    icrc1_decimals : () -> async Nat8;
    icrc1_transfer : ({
      from_subaccount : ?Subaccount;
      to : Account;
      amount : Tokens;
      fee : ?Tokens;
      memo : ?Memo;
      created_at_time : ?Timestamp;
    }) -> async Result<TxIndex, TransferError>;
  };

  public let MODCLUB_CANISTER_ID_QA = "hvyqe-cyaaa-aaaah-qdbiq-cai";
  public let MODCLUB_CANISTER_ID_DEV = "d7isk-4aaaa-aaaah-qdbsa-cai";
  public let MODCLUB_CANISTER_ID_PROD = "gwuzc-waaaa-aaaah-qdboa-cai";

  public let MODCLUB_LEDGER_QA = "vckh6-hqaaa-aaaah-qc7wa-cai";
  public let MODCLUB_LEDGER_DEV = "vxnwt-gyaaa-aaaah-qc7vq-cai";
  public let MODCLUB_LEDGER_PROD = "xsi2v-cyaaa-aaaaq-aabfq-cai";

  public func getModclubId(env: Text) : Text {
    switch(env) {
      case("prod") { MODCLUB_CANISTER_ID_PROD; };
      case("dev") { MODCLUB_CANISTER_ID_DEV; };
      case("qa") { MODCLUB_CANISTER_ID_QA; };
      case(_) {"2vxsx-fae"}; // anonymous
    };
  };

  public func getModclubLedgerId(env: Text) : Text {
    switch(env) {
      case("prod") { MODCLUB_LEDGER_PROD; };
      case("dev") { MODCLUB_LEDGER_DEV; };
      case("qa") { MODCLUB_LEDGER_QA; };
      case(_) {"2vxsx-fae"}; // anonymous
    };
  };

  public func getModclubActor(env: Text) : ModclubActorType {
     actor (getModclubId(env)) : ModclubActorType;
  };

  public func getModclubLedgerActor(env: Text) : ModclubLedgerActorType {
     actor (getModclubLedgerId(env)) : ModclubLedgerActorType;
  };

  public func initProvider(env : Text, name : Text, description : Text, ?companyLogo : ?Image) : async Result.Result<Bool, Text> {
    let modclub = getModclubActor(env);
    let resp = await modclub.registerProvider(name, description, ?companyLogo);
    if (Text.contains("Registration successful", #text resp) or Text.contains("already registered", #text resp)) {
      return #ok(true);
    };
    if (Text.contains("not in allow list", #text resp)) {
      throw Error.reject("Unable to register provider. Provider is not in whitelist.");
      return #err("Unable to register provider. Provider is not in whitelist.");
    };
    return #err("Unable to register provider." # resp);
  };

  public func topUpReserveBalance(env : Text, amount : Tokens) : async Result<TxIndex, TransferError> {
    let modclub = getModclubActor(env);
    let saReserve = await modclub.getProviderSa("RESERVE", null);
    let ledger = getModclubLedgerActor(env);
    await ledger.icrc1_transfer({
      from_subaccount = null;
      to = {
        owner = Principal.fromText(getModclubId(env));
        subaccount = ?saReserve;
      };
      amount;
      created_at_time = null;
      fee = null;
      memo = null;
    });
  };

  public func providerSaBalance(env : Text) : async Tokens {
    let modclub = getModclubActor(env);
    let saReserve = await modclub.getProviderSa("RESERVE", null);
    let ledger = getModclubLedgerActor(env);
    await ledger.icrc1_balance_of({
        owner = Principal.fromText(getModclubId(env));
        subaccount = ?saReserve;
    });
  };
};
