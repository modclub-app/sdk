import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Modclub "../../src/modclub";
// import Modclub "mo:modsdk/modclub";
import File "./files";

actor class ModclubProvider() = this {
    stable var ModclubRulesAdded = false;

    let env = "qa";
    let imageFile = File.File();
    let modclub = Modclub.getModclubActor(env);

    public shared({caller}) func submitContentToModclub() : async () {
        // Assumption: SetUpModclub method has already been called
        // Submit content to be reviewed by moderators
        let test1 = await modclub.submitText("id_1_categorized", "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", ?"Title for SHOOTER GAME Content", ?#normal, ?"HOWTO_FOR_SHOOTERS");
        let test2 = await modclub.submitText("id_2_categorized", "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", ?"Title for STRATEGY GAME Content", ?#normal, ?"HOWTO_FOR_STRATEGIES");
        let test3 = await modclub.submitText("id_5_categorized", "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", ?"Title for RPG game review", ?#normal, ?"RPPG_GAMES_REVIEWS");
    };

    public shared ({caller}) func ModclubCallback(result: Modclub.ContentResult) {
        Debug.print(debug_show(result));
    };

    public shared({caller}) func topUpProviderAccount(amount : Modclub.Tokens) : async Modclub.Result<Modclub.TxIndex, Modclub.TransferError> {
        await Modclub.topUpReserveBalance(env, amount);
    };

    public shared({caller}) func providerSaBalance() : async Modclub.Tokens {
        await Modclub.providerSaBalance(env);
    };

    public shared({caller}) func initModclubProvider() : async Text {
        let companyLogo : Modclub.Image = {
            data = imageFile.SoccerBall;
            imageType = "image/jpeg";
        };

        try {
            let init = await Modclub.initProvider(env, "TestProviderApp", "AppDescription", ?companyLogo);
            switch(init) {
                case(#ok(_)) {
                    if(not ModclubRulesAdded) {
                        let rules = [
                            "This post threatens violence against an individual or a group of people",
                            "This post glorifies violence",
                            "This post threatens or promotes terrorism or violent extremism",
                        ];
                        await modclub.addRules(rules, null);
                        ModclubRulesAdded := true;
                    };

                    await modclub.subscribe({callback = ModclubCallback;});
                    let _ = await Modclub.topUpReserveBalance(env, 10_000_000);
                    return "Initialization successfull.";
                };
                case(#err(message)) { return "Initialization failed :: " # message; };
            };
        } catch (e) {
            return Error.message(e);
        };

    };

    public shared({caller}) func exampleToGetPOHStatus(): async Text {
        // userId to check if they are a human or not
        let userId = "2vxsx-fae";
        // call to check humanity
        let response =  await modclub.verifyHumanity(userId);

        // The user is verified and this is the first time they have associated their account on your application to their modclub POH.
        if(response.status == #verified and response.isFirstAssociation) {
           // In most cases you will only want to accept a POH response that has isFirstAssociation = true so that a user can't reuse their POH 
           // with multiple accounts on your platform. For example an NFT allowlist will want the first association of an account to be accepted.
            return "User is verified and first association from your app to modclub";
        };
        
       // The user has been verified but is reusing their POH 
       if(response.status == #verified and not response.isFirstAssociation) {
            return "User is verified but is reusing their modclub POH for another account on your platofrm";
        };

        if((response.status == #startPoh or response.status == #notSubmitted) and response.isFirstAssociation) {
            return "User hasn't done POH or hasn't submitted it. Use this token to start POH: " # Option.get(response.token, "");
        };
        if(response.status == #verified) {
            return "User is verified";
        };
        
        // The POH has expired in accordance with your configuration. For instance you may only accept POH that was submitted in the last 6 months
        // If the user submitted their POH 7 months ago, then you would receive a status of #expired
        if(response.status == #expired) {
            return "User's POH is expired";
        };
        return "User's POH is pending for review";
    };
   
};
