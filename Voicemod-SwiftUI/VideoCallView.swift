//
//  VideoCallView.swift
//  Voicemod-SwiftUI
//
//  Created by Max Cobb on 09/09/2021.
//

import SwiftUI
import AgoraUIKit_iOS

struct VideoCallView: View {

    @State private var selection: String?

    let names = [
        "baby",
        "cave",
        "lost-soul",
        "robot",
        "titan"
    ]

    @Binding var joinedChannel: Bool
    @State var voicemodRegistered = false

    var body: some View {
        ZStack {
            ContentView.agview
            if joinedChannel {
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
                        }.padding(3).background(Color.black).cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
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
                            }.padding(.trailing, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                        }
                    }
                    Spacer()
                }
            }
        }

    }

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

        // Remove background music from all voices
        ContentView.agview.viewer.setExtensionProperty(
            "Voicemod", extension: "VoicemodExtension",
            key: "vcmd_user_data", value: false
        )
    }

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
}
