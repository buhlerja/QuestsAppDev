//
//  ObjectiveCreateView.swift
//  Prompts
//
//  Created by Jack Buhler on 2024-07-21.
//

import SwiftUI
import MapKit

struct ObjectiveCreateView: View {
    @Binding var showObjectiveCreateView: Bool
    @State private var tooManyObjectives: Bool = false
    @State private var noTitle: Bool = false
    @State private var noSolution: Bool = false
    @State private var noDescription: Bool = false
    @Binding var questContent: QuestStruc // Passed in from CreateQuestContentView
    @Binding var objectiveContent: ObjectiveStruc // Changed to @Binding
    
    @State private var hint: String = ""
    @State private var hrConstraint: Int = 0
    @State private var minConstraint: Int = 0
    @State private var originalHrConstraint: Int = 0
    @State private var originalMinConstraint: Int = 0

    var body: some View {
        ScrollView {
            VStack {
                
                // Objective Number set in function in QuestStruc file (during add objective)
                
                objectiveDescriptionView(objectiveDescription: $objectiveContent.objectiveDescription, objectiveTitle: $objectiveContent.objectiveTitle)
                             
             
                HStack {
                    Text("Objective Type: ")
                    Picker(selection: $objectiveContent.objectiveType, label: Text("Picker")) {
                        //Text("Location").tag(1) // ONLY COMBINATION AND CODE FOR RELEASE 1
                        //Text("Photo").tag(2)
                        Text("Code").tag(3)
                        Text("Combination").tag(4)
                    }
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }
                .padding()
                if objectiveContent.objectiveType == 3  || objectiveContent.objectiveType == 4 {
                    VStack {
                        if objectiveContent.objectiveType == 3 {
                            HStack {
                                Text("Solution: ")
                                TextField("Enter your solution", text: $objectiveContent.solutionCombinationAndCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                            } .padding()
                        }
                        else {
                            VStack {
                                Text("Solution: \(objectiveContent.solutionCombinationAndCode)")
                                    .padding()
                                NumericGrid() // Automatically adds the combination to the data structure
                            }
                        }
                        
                        HStack {
                            Text("Enter Time Constraint? (Optional)")
                            Spacer()
                        }
                        HStack {
                            Picker("Hours", selection: $hrConstraint) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour) h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 100)
                            .clipped()

                            Picker("Minutes", selection: $minConstraint) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 100)
                            .clipped()
                        }
                        .padding()
        
                        HStack {
                            Text("Add Hint? (Optional)") // Optionality of hint is handled
                            TextField("Enter your hint", text: $hint)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } .padding()
                        Text("Users will be able to access your hint after a failed attempt or after half of their time has expired")
                            .font(.footnote)
                        HStack {
                            Text("Add Area? (Optional)") // NEED TO ADD AN INDICATOR AS TO WHETHER AN AREA WAS ADDED OR NOT
                            Spacer()
                            // Followed by an AREA selector which appears below.
                        } .padding()
                        areaSelector(objectiveArea: $objectiveContent.objectiveArea)
                            .frame(width: 300, height: 300)
                            .cornerRadius(12)
                    } .padding()
                }
                
                // Cannot save objective
                if tooManyObjectives {
                    Text("Oops! Maximum number of Objectives reached")
                        .font(.subheadline)
                        .foregroundColor(.white) // Text color
                        .padding()              // Inner padding
                        .background(Color.red)  // Red background
                        .cornerRadius(8)        // Rounded corners
                        .shadow(radius: 4)      // Optional shadow for better visibility
                }
                if noTitle {
                    Text("Oops! Add a title to your Objective!")
                        .font(.subheadline)
                        .foregroundColor(.white) // Text color
                        .padding()              // Inner padding
                        .background(Color.red)  // Red background
                        .cornerRadius(8)        // Rounded corners
                        .shadow(radius: 4)      // Optional shadow for better visibility
                }
                if noDescription {
                    Text("Oops! Add a description to your Objective!")
                        .font(.subheadline)
                        .foregroundColor(.white) // Text color
                        .padding()              // Inner padding
                        .background(Color.red)  // Red background
                        .cornerRadius(8)        // Rounded corners
                        .shadow(radius: 4)      // Optional shadow for better visibility
                }
                if noSolution {
                    Text("Oops! Add a solution to your Objective!")
                        .font(.subheadline)
                        .foregroundColor(.white) // Text color
                        .padding()              // Inner padding
                        .background(Color.red)  // Red background
                        .cornerRadius(8)        // Rounded corners
                        .shadow(radius: 4)      // Optional shadow for better visibility
                }
                
                HStack {
                    Button(action: {
                        showObjectiveCreateView = false
                        objectiveContent.isEditing = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Cancel")
                                .padding()
                                .background(Color.cyan)
                                .cornerRadius(8)
                            Spacer()
                        }
                        
                    }
                    
                    Button(action: {
                        
                        // 1) Objective data is saved in objectiveContent Structure
                        noTitle = objectiveContent.objectiveTitle.isEmpty
                        noSolution = objectiveContent.solutionCombinationAndCode.isEmpty
                        noDescription = objectiveContent.objectiveDescription.isEmpty
                        if objectiveContent.isEditing == false {
                            // From the CREATE flow, not the EDIT flow, so append to struc
                            tooManyObjectives = questContent.objectiveCount >= Macros.MAX_OBJECTIVES
                            if !tooManyObjectives, !noTitle, !noSolution, !noDescription {
                                questContent.addObjective(objectiveContent)  /* 2) Append new ObjectiveStruc to array of ObjectiveStruc's that forms the objectives for this quest */
                                questContent.editTotalLength(objectiveContent) // Adjust the total length of quest based on objective length
                               
                                // 3) Display created objectives on screen (find some sort of sub-view to display objective info -> this is ObjectiveHighLevelView. This is done in CreateQuestContentView)
                                showObjectiveCreateView = false         /* 4) create another "create objective button" on screen. */
                            }
                           
                        }  // IF editing, the objective is already saved to the data structure, and it is modified directly by this view
                        else { // isEditing == true
                            // Editing flow
                            /* Following code is to adjust the total length parameter */
                            questContent.editTotalLength(objectiveContent, originalHrConstraint: originalHrConstraint, originalMinConstraint: originalMinConstraint) /* Need initial value of the time to SUBTRACT from totalLength before adding the NEW time (for edit only) */
                            
                            // Display created objectives on screen (find some sort of sub-view to display objective info -> this is ObjectiveHighLevelView. This is done in CreateQuestContentView)
                            if !noTitle, !noSolution, !noDescription {
                                showObjectiveCreateView = false         /* 4) create another "create objective button" on screen. */
                                // change editing boolean back to false
                                objectiveContent.isEditing = false
                            }
                        }
                        
                      
                    }) {
                          
                        HStack {
                            Spacer()
                            Text("Save Objective")
                                .padding()
                                .background(Color.cyan)
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
               
            }.padding()
        }
        .onAppear {
            // Set `hint` to the value of `objectiveContent.objectiveHint` if it exists, otherwise default to an empty string
            hint = objectiveContent.objectiveHint ?? ""
            hrConstraint = objectiveContent.hoursConstraint ?? 0
            minConstraint = objectiveContent.minutesConstraint ?? 0
            if objectiveContent.isEditing {
                originalHrConstraint = hrConstraint
                originalMinConstraint = minConstraint
            }
        }
        .onChange(of: hint) {
            objectiveContent.objectiveHint = hint.isEmpty ? nil : hint
        }
        .onChange(of: hrConstraint) {
            objectiveContent.hoursConstraint = hrConstraint == 0 ? nil : hrConstraint
        }
        .onChange(of: minConstraint) {
            objectiveContent.minutesConstraint = minConstraint == 0 ? nil : minConstraint
        }
    }
    
    // A helper function to display a number as a button
     func number(of number: Int) -> some View {
         Button(action: {
             objectiveContent.solutionCombinationAndCode += "\(number)"
         }) {
             ZStack {
                 Circle()
                     .fill(Color.cyan) // Set the color for the circle
                     .frame(width: 50, height: 50) // Set the size of the circle
                 Text("\(number)")
                     .font(.title)
                     .foregroundColor(.white) // Set the text color
             }
         }
         .accessibilityLabel(Text("Button \(number)")) // Accessibility label
     }
    
    // View for the numeric grid
    func NumericGrid() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(1..<10) { digit in
                    number(of: digit)
                }
            }
            number(of: 0)
        }
        .padding()
    }
    
    // Helper function containing objective description sub-view
    private func objectiveDescriptionView(objectiveDescription: Binding<String>, objectiveTitle: Binding<String>) -> some View
    {
        VStack(alignment: .leading) {
             Text("Title of Objective: ")
             TextField("Title", text: objectiveTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
             Text("Description of Objective: ")
             Text("This is the set of instructions the adventurer will be presented with")
                 .font(.subheadline)
                 .padding(.top, 2)
         
             TextEditor(text: objectiveDescription)
               .padding(4)
               .frame(height: 200)
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
        .padding()
    }
    
}



struct ObjectiveCreateView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectiveCreateView(showObjectiveCreateView: .constant(false),
                            questContent: .constant(
                                QuestStruc(coordinateStart: CLLocationCoordinate2D(
                                    latitude: 0.0,
                                    longitude: 0.0),
                                    title: "",
                                    description: "",
                                    supportingInfo: SupportingInfoStruc.sampleData
                                
                                )
                            ),
                            objectiveContent: .constant(
                                ObjectiveStruc(
                                    objectiveNumber: 0,
                                    objectiveTitle: "Wash me",
                                    objectiveDescription: "Break into an old folks home and give someone a bath",
                                    objectiveType: 3,
                                    solutionCombinationAndCode: "",
                                    // objectiveHint automatically initialized as nil
                                    objectiveArea: (CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589), CLLocationDistance(1000)),
                                    isEditing: false
                                )
                            )
        )
    }
}
