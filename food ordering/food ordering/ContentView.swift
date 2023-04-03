import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var isShowingLocationAccess = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("We need your location to find restaurants near you.")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                NavigationLink(
                    destination: RestaurantView(),
                    isActive: $isShowingLocationAccess
                ) {
                    Text("Enable Location Access")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
            }
            .onAppear() {
                checkLocationAccess()
            }
        }
    }
    
    func checkLocationAccess() {
        if CLLocationManager.locationServicesEnabled() {
            locationStatus = CLLocationManager.authorizationStatus()
        }
        if locationStatus == .notDetermined {
            isShowingLocationAccess = true
        }
    }
}

struct RestaurantView: View {
    @State private var isMapExpanded = false
    @State private var isCartViewShowing = false
    @State private var cartItems: [FoodItem] = []
    let restaurantName = "Sample Restaurant"
    @State private var foodItems: [FoodItem] = []
    
    var body: some View {
        VStack {
            MapView().frame(height: isMapExpanded ? UIScreen.main.bounds.height : 200)
                .gesture(TapGesture().onEnded {
                    self.isMapExpanded.toggle()
                })

            Image("restaurant_image").resizable().scaledToFit()
                .overlay(Text(restaurantName).foregroundColor(.white).font(.title).padding(), alignment: .bottomLeading)

            ScrollView {
                ForEach(foodItems) { item in
                    HStack {
                        Text(item.name).font(.headline)
                        Spacer()
                        Text("$\(item.price)").font(.subheadline).foregroundColor(.secondary)
                        Button(action: {
                            self.addToCart(item)
                        }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.green)
                        }
                    }.padding()
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button(action: {
                    self.isCartViewShowing.toggle()
                }) {
                    Image(systemName: "cart.badge.plus").font(.system(size: 30))
                }.padding()
            }.padding(.bottom)
        }
        .sheet(isPresented: $isCartViewShowing) {
            CartView(cartItems: self.$cartItems, isCartViewShowing: self.$isCartViewShowing)
        }
        .onAppear() {
            self.loadFoodItems()
        }
    }
    
    private func loadFoodItems() {
        if let url = Bundle.main.url(forResource: "fooditem", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let foodItems = try JSONDecoder().decode([FoodItem].self, from: data)
                self.foodItems = foodItems
            } catch {
                print("Error decoding food items: \(error.localizedDescription)")
            }
        } else {
            print("Error loading food items file")
        }
    }


    private func addToCart(_ item: FoodItem) {
        cartItems.append(item)
    }
}
struct Result: Decodable {
    let data: [FoodItem]
}

struct FoodItem: Identifiable, Decodable {
    var id = UUID()
    var name: String
    var price: Double
    var isSide: Bool
    var suggestedSides: [String]?
}

struct MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let coordinate = CLLocationCoordinate2D(latitude: 37.786996, longitude: -122.419281)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        view.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Sample Restaurant"
        view.addAnnotation(annotation)
    }
}

struct CartView: View {
    @Binding var cartItems: [FoodItem]
    @Binding var isCartViewShowing: Bool

    var body: some View {
        VStack {
            Text("Cart").font(.largeTitle).fontWeight(.bold).padding()

            List(cartItems) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text("$\(item.price, specifier: "%.2f")").foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                self.isCartViewShowing.toggle()
            }) {
                Text("Close").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.blue).cornerRadius(10)
            }.padding(.bottom)
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
