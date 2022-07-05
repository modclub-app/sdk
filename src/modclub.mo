import Text "mo:base/Text";
import Nat "mo:base/Nat";

// This is the interface to modclub for providers
module {

  type ContentId = Text;
  public type ContentStatus = {
    #approved;
    #rejected;
    #reviewRequired;
  };

  public type ContentResult = {
    sourceId: Text;
    status: ContentStatus;
  };

  public type ProviderSettings = {
    minVotes: Nat;
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

  public type ModclubActorType = actor {
    registerProvider: (Text, Text, ?Image) -> async Text;
    deregisterProvider: () -> async Text;
    addRules: ([Text], ?Principal) -> async ();
    removeRules: ([Text], ?Principal) -> async ();
    getProviderRegisteredRules: () -> async [Rule];
    addProviderAdmin:(Principal, Text, ?Principal) -> async ();
    removeProviderAdmin: (Principal, Principal) -> async ();
    updateSettings: (ProviderSettings) -> async ();
    submitText: (Text, Text, ?Text) -> async Text;
    submitImage: (Text, [Nat8], Text, ?Text) -> async Text;
    submitHtmlContent: (Text, Text, ?Text) -> async Text;
    subscribe: (SubscribeMessage) -> async ();
    // Proof of Humanity APIs
    verifyHumanity: (Text) -> async PohVerificationResponsePlus;
    subscribePohCallback: (SubscribePohMessage) -> async ();
  };

  public let MODCLUB_CANISTER_ID_DEV = "olc6u-lqaaa-aaaah-qcooq-cai";
  public let MODCLUB_DEV_ACTOR = actor "olc6u-lqaaa-aaaah-qcooq-cai" : ModclubActorType;

  public let MODCLUB_CANISTER_ID_PROD = "la3yy-gaaaa-aaaah-qaiuq-cai";
  public let  MODCLUB_PROD_ACTOR =  actor "la3yy-gaaaa-aaaah-qaiuq-cai" : ModclubActorType;

  public func getModclubId(environment: Text) : Text {
    if(environment == "prod") {
      return MODCLUB_CANISTER_ID_PROD;
    } else {
      return MODCLUB_CANISTER_ID_DEV; 
    };
  };

  public func getModclubActor(environment: Text) : ModclubActorType {
    if(environment == "prod") {
      return MODCLUB_PROD_ACTOR;
    } else {
      return MODCLUB_DEV_ACTOR;
    };
  };
};
