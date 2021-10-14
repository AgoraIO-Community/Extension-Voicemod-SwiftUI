# Create a Voice Changing Video Call app with SwiftUI 

See how you can make a simple voice changing application using with Agora UIKit in SwiftUI and Voicemod’s Extension.

## Prerequisites

- An Agora developer account (see [How To Get Started with Agora](https://www.agora.io/en/blog/how-to-get-started-with-agora?utm_source=medium&utm_medium=blog&utm_campaign=extension-voicemod-swiftui))
- Xcode 12.3 or later
- A physical iOS device with iOS 13.0 or later
- A basic understanding of iOS development

## Setup

Let’s start with a new, single-view iOS project. Create the project in Xcode, choosing SwftUI for the interface, and then add Agora's UIKit Package.

Add the package by opening selecting `File > Swift Packages > Add Package Dependency`, then paste in the link to this Swift Package:

`https://github.com/AgoraIO-Community/iOS-UIKit.git`

When asked for the version, insert `4.0.0-preview`, and select "Up to Next Major". This should install at least version `4.0.0-preview.7`, which is released at the time of writing this article.

If in doubt, you can always select "Exact", and insert `4.0.0-preview.7`.

---

Once that package installed, the camera and microphone usage descriptions need to be added. To see how to do that, check out Apple's documentation here:

https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios#2962313

## Video Call UI

I won't go into much detail when it comes to the UI here, as we're mostly focusing on the Voicemod extension, but on a high level:

- The ContentView contains two views, a VideoCallView (defined in project), and a button to join the channel.
- ContentView holds the active AgoraViewer, which is brought in from Agora UIKit.
- When the button is pushed, the Agora UIKit method `join(channel:,with:,as:)` is called which joins the Agora Video channel.

This is what the ContentView looks like:

```swift
struct ContentView: View {
    @State var joinedChannel: Bool = false
    static var agview: AgoraViewer = {
        AgoraViewer(
            connectionData: AgoraConnectionData(
                appId: AppKeys.agoraAppId
            ),
            style: .floating
        )
    }()

    var body: some View {
        ZStack {
            VideoCallView(joinedChannel: $joinedChannel)
            if !joinedChannel {
                Button("Join Channel") {
                    self.joinChannel()
                }
            }
        }
    }

    func joinChannel() {
        self.joinedChannel = true
        ContentView.agview.join(
            channel: "test", with: AppKeys.agoraToken,
            as: .broadcaster
        )
    }
}
```

And the VideoCallView, without any of the voicemod additions looks like this:

```swift
struct VideoCallView: View {
    @Binding var joinedChannel: Bool
    var body: some View {
        ZStack {
            ContentView.agview
        }
    }
}
```

---

We now have a working video call app with SwiftUI and Agora UIKit. Let's add voicemod!

## Integrating Vocemod

### Voicemod Credentials

If you have an account with Agora and are currently signed in, follow [this link](https://console.agora.io/marketplace/extension/introduce?serviceName=voicemod) to activate the voicemod extension for your account.

First you will need to activate Voicemod for your account by clicking "Activate" here:

![extension-activate](media/extension-activate.jpg)

Next, enable it for the project, the same project for the Agora App ID used in the app:

![extension-enable-project](media/extension-enable-project.jpg)

Once that's done, you can grab your Voicemod `API Key` and `API Secret` by clicking here:

![extension-credentials](media/extension-credentials.jpg)



### Add to Xcode

We need to add Voicemod's extension, which can also be installed via Swift Package Manager with the following URL:

`https://github.com/AgoraIO-Community/Extension-Voicemod-iOS`

> The latest release at the time of writing this is `0.0.1`.

This package doesn't need importing in your Swift code, it just needs to be bundled alongside Agora's SDK.

### Enable the Extension

Whenever using Agora Extensions, you need to enable them before joining a channel.

To do this with Agora UIKit, you can call `AgoraVideoViewer.enableExtension()`.

This method needs to be passed the vendor ("Voicemod"), the vendor extension ("VoicemodExtension") in this case:

```swift
ContentView.agview.viewer.enableExtension(
  withVendor: "Voicemod", extension: "VoicemodExtension", enabled: true
)
```

The above code snippet has been added to the beginning of the `joinChannel` method defined earlier.

### Choose the Voice

Once joining the channel, we'll add a small menu to the top of our view. This menu will contain all the available voices from Voicemod, and on selecting it we'll call a method to make sure we're using that voice. On selecting an option, we update a state variable, `selection`.

The menu is created like this:

```swift
VStack {
  HStack {
    Spacer()
    Menu {
      ForEach(values: names) { name in
        Button {
          selection = name
        } label: {
          Text(name)
        }
      }
      if selection != nil {
        Button {
          selection = nil
        } label: {
          Text("Clear")
          Spacer()
          Image(systemName: "clear")
        }
      }
    } label: {
      Image(systemName: "speaker.wave.3")
      Text(selection ?? "Select a Voice")
    }.padding(3).background(Color.black).cornerRadius(3.0)
    .onChange(of: selection, perform: { value in
      // update value for voicemod
      self.setVoicemodParam(to: selection ?? "null")
    })
    Spacer()

    if selection != nil {
      Button {
        selection = nil
      } label: {
        Image(systemName: "xmark.circle")
      }.padding(.trailing, 10)
    }
  }
}
```

And the names array is defined as this:

```swift
let names = [
    "baby",
    "cave",
    "lost-soul",
    "robot",
    "titan"
]
```

This is what the menu looks like:

![voicemod-menu](media/voicemod-menu.gif)

---

Almost there now! The only thing left to do is define the setVoicemodParam method.

This method needs to do two things:

- Initialise voicemod, passing the API Key and API Secret values.
- Set the voice property, so it knows which voice effect you want to have.

Firstly, let's define a function `registerVoicemod` for setting the key and secret.

```swift
func registerVoicemod() {
  // Set API Credentials
  let dataDict = [
    "apiKey": AppKeys.voicemodApiKey,
    "apiSecret": AppKeys.voicemodApiSecret
  ]
  guard let setPropertyResp = ContentView.agview.viewer.setExtensionProperty(
    "Voicemod", extension: "VoicemodExtension",
    key: "vcmd_user_data", codable: dataDict
  ), setPropertyResp == 0 else {
    print("Could not set extension property")
    return
  }

  self.voicemodRegistered = true
}
```

Here we are using the method `setExtensionProperty` with the `vcmd_user_data` key. The apiKey and apiSecret are stored as a JSON string, but this method from Agora UIKit allows us to pass a Swift dictionary, where it will then encode it automatically.

If something goes wrong, either setPropertyResp will be null, or the response will be less than zero; but if all the steps are followed there should be no issues!

Now the method `setVoicemodParam` can be defined; calling `registerVoicemod` the first time, and then setting the voice value (robot, baby etc.):

```swift
func setVoicemodParam(to voiceName: String) {
  if !self.voicemodRegistered {
    self.registerVoicemod()
  }

  // SET VOICE
  ContentView.agview.viewer.setExtensionProperty(
    "Voicemod", extension: "VoicemodExtension",
    key: "vcmd_voice", strValue: voiceName
  )
}

```

## Conclusion

You now have a video calling app complete with the new extension from Voicemod!

There are other extensions I'd encourage you to try out, and they can all be found here:

https://console.agora.io/marketplace

## Testing

You can try this app out by following the GitHub link here:

https://github.com/AgoraIO-Community/Extension-Voicemod-SwiftUI

## Other Resources

For more information about building applications using Agora.io SDKs, take a look at the [Agora Video Call Quickstart Guide](https://docs.agora.io/en/Video/start_call_ios?platform=iOS&utm_source=medium&utm_medium=blog&utm_campaign=extension-voicemod-swiftui) and [Agora API Reference](https://docs.agora.io/en/Video/API Reference/oc/docs/headers/Agora-Objective-C-API-Overview.html?utm_source=medium&utm_medium=blog&utm_campaign=extension-voicemod-swiftui).

I also invite you to [join the Agora.io Developer Slack community](https://www.agora.io/en/join-slack/).

