import SwiftUI

@main
struct AnimationBugApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct FavoriteNumber: Identifiable {
    var id: Int
    var value: Int
}

struct ContentView: View {
    @State private var favNumbers: [FavoriteNumber] = [
        .init(id: 1, value: 23),
        .init(id: 2, value: 42),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(favNumbers) { num in
                        NavigationLink(value: num.id) {
                            Text("ID \(num.id)")
                                .badge(num.value)
                        }
                    }
                } footer: {
                    Text("Drill down to the detail view to see the broken animation. Observed on iOS 16.1 and macOS 13.0.")
                }
            }
            .navigationTitle("Root")
            .navigationDestination(for: FavoriteNumber.ID.self) { id in
                // Detail view requires a Binding.
                // Given an item ID, derive a Binding to an array element.
                let index = favNumbers.firstIndex(where: { $0.id == id })!
                Detail(favNumber: $favNumbers[index])
            }
        }
    }
}

enum AnimationStyle {
    case withAnimation
    case animationModifier
}

struct Detail: View {
    @Binding var favNumber: FavoriteNumber
    @State private var animationStyle: AnimationStyle = .withAnimation

    var body: some View {
        let isEven = favNumber.value.isMultiple(of: 2)
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                LabeledContent {
                    Picker("Animation style", selection: $animationStyle) {
                        Text(".withAnimation")
                            .tag(AnimationStyle.withAnimation)
                        Text(".animation")
                            .tag(AnimationStyle.animationModifier)
                    }
                    .pickerStyle(.menu)
                } label: {
                    Text("Animation style")
                }

                Text("Choose an animation style and tap the button. Observe how the animation breaks when you select `.withAnimation`, but works fine with `.animation`.\n\nThe problem seems to be the way the parent view creates the Binding for this view in `.navigationDestination(for:)`.")
                    .font(.footnote)
            }
            .multilineTextAlignment(.leading)

            Button("Tap me to animate!") {
                switch animationStyle {
                case .withAnimation:
                    // FIXME: This animation doesn’t work. Why?
                    withAnimation(.default) {
                        favNumber.value += 1
                    }
                case .animationModifier:
                    favNumber.value += 1
                }
            }
            .font(.title3)
            .buttonStyle(.borderedProminent)

            Text("\(favNumber.value)")
                .font(.largeTitle.bold().monospacedDigit())
                .padding(isEven ? 50 : 25)
                .background {
                    Rectangle()
                        .fill(isEven ? Color.pink : .yellow)
                }
                .navigationTitle("Item \(favNumber.id)")
                .frame(maxHeight: .infinity)
        }
        // This animation works fine (as expected).
        .animation(
            animationStyle == .animationModifier ? .default : nil,
            value: favNumber.value
        )
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
