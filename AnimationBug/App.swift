import SwiftUI

@main
struct AnimationBugApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct FavoriteNumber: Identifiable, Equatable {
    var id: Int
    var value: Int
}

struct ContentView: View {
    @State private var favNumbers: [FavoriteNumber] = [
        .init(id: 1, value: 23),
    ]

    var body: some View {
        let _ = Self._printChanges()
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
                DetailWrapper(id: id, favNumbers: $favNumbers)
            }
        }
    }
}

/// Workaround for otherwise broken `withAnimation` in Detail view.
///
/// Injecting this wrapper view in the middle, and thus not creating the Binding
/// directly inside `navigationDestination(for:)`, fixes the animation in Detail
/// view.
struct DetailWrapper: View {
    var id: FavoriteNumber.ID
    @Binding var favNumbers: [FavoriteNumber]

    var body: some View {
        // Detail view requires a Binding.
        // Given an item ID, derive a Binding to an array element.
        let index = favNumbers.firstIndex(where: { $0.id == id })!
        Detail(favNumber: $favNumbers[index])
    }
}

struct Detail: View {
    @Binding var favNumber: FavoriteNumber

    var body: some View {
        let _ = Self._printChanges()
        let isEven = favNumber.value.isMultiple(of: 2)
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Tap the button. Observe that the animation now works correctly, after we added the workaround.")
                    .font(.footnote)
            }
            .multilineTextAlignment(.leading)

            Button("Tap me to animate!") {
                withAnimation(.default) {
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
                // Animating with `.animation` works fine.
//                .animation(.default, value: favNumber)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        // The animation works when you use the Detail view outside a navigation
        // view, which makes me think the problem is the way we create the Binding
        // in navigationDestination(for:).
        WithState(FavoriteNumber(id: 1, value: 23)) { $num in
            Detail(favNumber: $num)
        }
    }
}
