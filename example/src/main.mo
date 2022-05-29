import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Modclub "mo:modsdk/modclub";
import File "./files";

actor {

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
        await Modclub.getModclubActor(environment).updateSettings({minVotes = 2; minStaked = 15});
        await Modclub.getModclubActor(environment).subscribe({callback = ModclubCallback;});
    };


    public shared({caller}) func exampleToInitiatePOH(): async ({#notAttempted; #pending; #rejected; #expired; #verified;#notSubmitted;}, ?Text) {
        // userId to check if it's a human or not
        let userId = Principal.fromText("2vxsx-fae");
        // call to check humanity
        let response =  await Modclub.getModclubActor(environment).pohVerificationRequest(userId);

        // If it's not a verified account then generate token to be used in iframe
        if(response.status != #verified) {
            return (response.status, ?(await Modclub.getModclubActor(environment).pohGenerateUniqueToken(userId)).token);
        };
        return (response.status, null);
    };
   
};