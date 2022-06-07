# MODCLUB

MODCLUB is a moderation platform for online apps deployed on the IC. Moderation as a service (MaaS) is the concept of outsourcing controversial decisions or risky content in order to protect users and maintain trust within communities.


# Usage
To integrate with MODCLUB, you need to perform the below steps:
1. Provide your canister ID to MODCLUB team first so that it can be allowed listed.
2. Import Modclub sdk in to your canister either using vessel(recommended) or copy pasting the src/modclub.mo file. Example provided uses vessel to fetch Modclub SDK for integration.

To register:
```js
// If you are using Vessel
import Modclub "mo:modsdk/modclub";

// If you are using SDK after copy pasting the modclub.mo file.
import Modclub "./modclub";

actor {

    public func setup() {
        let companyLogoInNat8Format : [Nat8] = [255, 216, 255, 224, 0];
        let companyLogo : Modclub.Image = {
            data = companyLogoInNat8Format;
            imageType = "image/jpeg";
        };
        // Register with Modclub
        let _ = await Modclub.getModclubActor("staging").registerProvider("AppName", "AppDescription", ?companyLogo);
    }
}
```

### Managing Content Rules

Once registered, you can set the rules that moderators should use to evaluate if the submitted content violates those them or not.

**addRules** - Add content rules
Params:
- *rules* - [Text] - An array of Texts that describe your content rules
- *providerId* - ?Principal - Optional Canister/Provider Id for which rules need to be registered

**removeRules** - Remove existing rules
Params:
- *ruleIds* - [Text] - An array of Rule Ids that you would like to remove
- *providerId* - ?Principal - Optional Canister/Provider Id for which rules need to be removed

**getRules** - Returns the list of rules you have provided
Params:
- *providerId* - Principal - Optional Canister/Provider Id for which rules need to be retrieved


### Registering Callback
In order for your application to be aware of when some content has been either approved or rejected, you can register a callback with MODCLUB.

**subscribe** - Suscribe your call back with MODCLUB
Params:
- *callback* - SubscribeMessage - The callback function you want to subscribe

The callback should have the following type
```js
  public type SubscribeMessage = { callback: shared ContentResult -> (); };
```

Example of registering your callback:
```js
  public func subscribe() : async() {
    await Modclub.getModclubActor("staging").subscribe({callback = voteResult;});

  };
    
  public func voteResult(result: ContentResult) {
      Debug.print(debug_show(result));
  };
```

### Submitting Content

Once your app is registered you can submit content to MODCLUB to be reviewed. Use the following methods to submit content:

**submitText**
Params:
- *sourceId* - Text - The unique ID for this content on your platform. 
- *text* - Text - The text content to be reviewed
- *title* (optional) - Text - An optional title for this content

```js
await Modclub.getModclubActor("staging").submitText("my_content_id", "Text content to be reviewed", ?"Title of content");
```

**submitHtmlContent**
Params:
- *sourceId* - Text - The unique ID for this content on your platform. 
- *htmlContent* - Text - The html content to be reviewed
- *title* (optional) - Text - An optional title for this content

```js
await Modclub.getModclubActor("staging").submitHtmlContent("my_content_id_123", "<p>Text content to be reviewed</p><img src='/image.png'/>", ?"Title of content");
```

**submitImage**
Params:
- *sourceId* - Text - The unique ID for this content on your platform. 
- *image* - [Nat8] - A Nat8 array containing the image data 
- *imageType* - Text - The image mime type i.e image/jpeg, image/png etc..
- *title* (optional) - Text - An optional title for this content

```js
await Modclub.getModclubActor("staging").submitImage("my_content_id", imageData, "image/png", ?"Title of Image Content");
```

### Adding an Admin
You can add admins to manage your application via our Admin dashboard. This is more convenient if you have other team members that are setting your app's content rules or the moderator settings.

**addProviderAdmin**
Params:
- *userName* - Text - The username for the admin
- *userPrincipal* - Principal - The principal ID for the admin
- *providerId* - ?Principal - The principal ID of your app. (Optional if your app is making this call directly) 

### Managing Moderator settings
You can adjust the number of votes required for content to be approved / rejected and the number of staked tokens to vote.

**updateSettings**
Params:
- *settings* - ProviderSettings
- *minVotes* - Nat - The minimum number of votes required in order for the decision to be finalized
- *minStaked* - Nat - The minimum number of MODCLUB points needed to be staked in order for a moderator to vote on your content.

```js
  await Modclub.getModclubActor("staging").updateSettings({minVotes = 2; minStaked = 100});
```