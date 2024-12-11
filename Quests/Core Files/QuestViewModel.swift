//
//  QuestViewModel.swift
//  Quests
//
//  Created by Jack Buhler on 2024-12-02.
//

import Foundation
import FirebaseFirestore

@MainActor
final class QuestViewModel: ObservableObject {
    
    private let mapViewModel: MapViewModel
    
    init(mapViewModel: MapViewModel) {
        self.mapViewModel = mapViewModel
    }
    
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var quests: [QuestStruc] = []
    @Published var selectedFilter: FilterOption? = nil
    @Published var recurringOption: RecurringOption? = nil
    
    private var lastDocument: DocumentSnapshot? = nil
    
    func loadCurrentUser() async throws { // DONE REDUNDANTLY HERE, IN PROFILE VIEW, AND IN CREATEQUESTCONTENTVIEW. SHOULD PROLLY DO ONCE.
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    enum FilterOption: String, CaseIterable {
        case noFilter
        case costHigh
        case costLow
        //case durationHigh
        //case durationLow
        
        var costAscending: Bool? {
            switch self {
            case .noFilter: return nil
            case .costLow: return true
            case .costHigh: return false
            }
        }
    }
    
    func filterSelected(option: FilterOption) async throws {
        
        self.selectedFilter = option
        self.getQuests()
        
    }
    
    enum RecurringOption: String, CaseIterable {
        case none
        case recurring
        case nonRecurring
        
        var recurringBool: Bool? {
            switch self {
            case .recurring: return true
            case .none: return nil
            case .nonRecurring: return false
            }
        }
    }
    
    func recurringOptionSelected(option: RecurringOption) async throws {
        self.recurringOption = option
        self.getQuests()
    }
        
    func getQuests() {
        Task {
            print("Getting quests")
            // Get the user's location to view relevant quests
            if let userLocation = try? await mapViewModel.getLiveLocationUpdates() {
                //let userCoordinate = userLocation.coordinate
                //print("User Coordinate: \(userCoordinate)")
                /*self.quests = try await QuestManager.shared.getAllQuests(costAscending: selectedFilter?.costAscending, recurring: recurringOption?.recurringBool)*/ // BRING BACK I ONLY COMMENTED FOR TESTING
                let (newQuests, lastDocument) = try await QuestManager.shared.getQuestsByProximity(count: 4, lastDocument: lastDocument, userLocation: userLocation) // COMMENT OUT, THIS IS CODE JUST TO TEST MY FUNCTION. FUNCTION WILL EVENTUALLY BE USED BUT IDK HOW
                self.quests.append(contentsOf: newQuests) // Bug where the query fetches the same quest and appends the duplicate. I think because there is only a single item returned by the query, so there is no "next document".
                self.lastDocument = lastDocument
                print("Got quests")
            } else {
                print("No user location available. Failed to retrieve relevant quests")
                // NEED TO HANDLE GRACEFULLY!!
                return // Exit if no user location is available
            }
        }
    }
    
    /*func getAllQuests() async throws {
        self.quests = try await QuestManager.shared.getAllQuests()
    }*/
    
    func addUserWatchlistQuest(questId: String) {
        guard let user else { return } // Make sure the user is logged in or authenticated
        // Add the quest to the USER database AND to the QUESTS database
        Task {
            // Add to user database
            try await UserManager.shared.addUserWatchlistQuest(userId: user.userId, questId: questId)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
            print("Successfully added to watchlist")
        }
    }
    
    /*func getQuestsByRating() {
        Task {
            //let newQuests = try await QuestManager.shared.getQuestsByRating(count: 3, lastRating: self.quests.last?.metaData.rating)
            let (newQuests, lastDocument) = try await QuestManager.shared.getQuestsByRating(count: 3, lastDocument: lastDocument)
            self.quests.append(contentsOf: newQuests)
            self.lastDocument = lastDocument
        }
    }*/ // Works but not needed
    
}
