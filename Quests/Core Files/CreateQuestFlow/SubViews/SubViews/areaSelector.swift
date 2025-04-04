//
//  areaSelector.swift
//  Prompts
//
//  Created by Jack Buhler on 2024-09-13.
//

import SwiftUI
import MapKit

struct areaSelector: View {
    @Binding var objectiveArea: ObjectiveArea
    @State private var position: MapCameraPosition = .automatic
    @State private var areaChosen = false
    
    var body: some View {
        ZStack {
            MapReader { proxy in
                VStack {
                    Map(position: $position) {
                        if areaChosen == true {
                            if let center = objectiveArea.center {
                                MapCircle(center: center, radius: objectiveArea.range)
                                    .foregroundStyle(Color.cyan.opacity(0.5)) // Fill with cyan color and 50% opacity
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {  // Convert tapped location to coordinate
                            objectiveArea.center = coordinate
                            if areaChosen == false {
                                areaChosen = true
                            }
                        }
                    }
                    HStack {
                        Text("Circle Radius")
                        // Slider to adjust the circle range
                        Slider(value: $objectiveArea.range, in: 10...10000, step: 100)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding()
                }
                .frame(height: 300)
                .border(Color(.black))
                .padding()
            }
        }
        
    }
}

struct areaSelector_Previews: PreviewProvider {
    static var previews: some View {
        areaSelector(
            objectiveArea: .constant(ObjectiveArea(center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589), range: CLLocationDistance(1000))))
        //.previewLayout(.fixed(width: 400, height: 400))
    }
}
