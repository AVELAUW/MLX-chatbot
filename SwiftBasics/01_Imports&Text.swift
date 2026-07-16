// Your AI App!!

//  COPY & PASTE: This is your starter file.
//    Copy EVERYTHING below and paste it into ContentView.swift
// *    replace the " ? " with your own text!

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

struct ContentView: View {

        @State private var userMessage = ""

        //Section 2: Suggested Questions Array

    var body: some View {
       
        VStack(spacing: 0) {

            //Section 3: App Icon
            
            VStack(spacing: 16) {
                Spacer()

                // ★ CHANGE THE TEXT BELOW TO YOUR OWN WELCOME MESSAGE:
                    Text( " ? " )
                        .font(.largeTitle.bold())

                // ★ CHANGE THIS SUBTITLE TO DESCRIBE YOUR APP:
                    Text(" ? ")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            print(question)
                        }) {
                            Text(question)
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 30))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
                Spacer()
            }
            .padding()


            Divider()

            HStack(alignment: .center, spacing: 12) {

                //Section 4: message box (text)

                Button("Send") {
                    print("Sent: \(userMessage)")
                    userMessage = ""
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 44)        }

    }
}

#Preview {
    ContentView()
}

