import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Modclub "mo:modsdk/modclub";
import File "./files";

actor class ModclubProvider() = this {

    let imageFile = File.File();

    public shared({caller}) func howToSubmitContentToModclub() : async () {
        // Assumption: SetUpModclub method has already been called
        // Submit content to be reviewed by moderators
        let test1 = await Modclub.getModclubActor(environment).submitText("id_1", "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", ?"Title for Text Content");
        let test2 = await Modclub.getModclubActor(environment).submitImage("id_4", imageFile.SoccerBall, "image/jpeg", ?"Title for Image Content" );
        let test3 = await Modclub.getModclubActor(environment).submitHtmlContent("id_5", "<p>Sample Html Content</p>", ?"Title for Html Content" );
    };

    public shared ({caller}) func ModclubCallback(result: Modclub.ContentResult) {
        Debug.print(debug_show(result));
    };

    stable var environment = "local";
    stable var ModclubRulesAdded = false;
    public shared({caller}) func setUpModclub(env: Text) {
        // Restrict the caller to admins or trusted identites only.
        if(env != "local" and env != "staging" and env != "prod") {
            throw Error.reject("Please Provide correct environment value");
        };
        environment := env;
        // On local don't set up Modclub
        if(environment == "local") {
            return;
        };
        let companyLogo : Modclub.Image = {
            data = imageFile.SoccerBall;
            imageType = "image/jpeg";
        };
        let _ = await Modclub.getModclubActor(environment).registerProvider("AppName", "AppDescription", ?companyLogo);
        if(not ModclubRulesAdded) {
            let rules = ["This post threatens violence against an individual or a group of people",
                "This post glorifies violence",
                "This post threatens or promotes terrorism or violent extremism",
            ];
            await Modclub.getModclubActor(environment).addRules(rules, null);
            ModclubRulesAdded := true;
        };
        await Modclub.getModclubActor(environment).updateSettings(Principal.fromActor(this), {minVotes = 2; minStaked = 15});
        await Modclub.getModclubActor(environment).subscribe({callback = ModclubCallback;});
    };


    public shared({caller}) func exampleToInitiatePOH(): async Text {
        // userId to check if they are a human or not
        let userId = "2vxsx-fae";
        // call to check humanity
        let response =  await Modclub.getModclubActor(environment).verifyHumanity(userId);

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
