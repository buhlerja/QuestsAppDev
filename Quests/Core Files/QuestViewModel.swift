//
//  QuestViewModel.swift
//  Quests
//
//  Created by Jack Buhler on 2024-12-02.
//

import Foundation
import FirebaseFirestore
import CoreLocation // Neded?
import GeoFire // For location based querying!

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
    
    @Published var noMoreToQuery: Bool = false
    @Published var userCoordinate: CLLocationCoordinate2D? = nil
    
    //private var lastDocument: DocumentSnapshot? = nil
    private var queriesWithLastDocuments: [(Query, DocumentSnapshot?)] = []
    
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
        self.quests = []
        //self.lastDocument = nil // BRING BACK IF YOU WANT FILTERS
        self.queriesWithLastDocuments = []
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
        self.quests = []
        //self.lastDocument = nil // BRING BACK IF YOU WANT FILTERS
        self.queriesWithLastDocuments = []
        self.getQuests()
    }
    
    func getUserLocation() async throws {
        if let userLocation = try? await mapViewModel.getLiveLocationUpdates() {
            self.userCoordinate = userLocation.coordinate
            print("User Coordinate: \(String(describing: userCoordinate))")
        }
    }
        
    func getQuests() {
        Task {
            // GET ALL QUESTS START
            /*let (newQuests, lastDocument) = try await QuestManager.shared.getAllQuests(costAscending: selectedFilter?.costAscending, recurring: recurringOption?.recurringBool, count: 10, lastDocument: lastDocument)
            self.quests.append(contentsOf: newQuests)
            if let lastDocument { // Stops bug. LastDocument is set to nil after a failed / last query
                self.lastDocument = lastDocument
            }*/
            // GET ALL QUESTS ENDS
            
            // GET QUESTS BY PROXIMITY START
            if !noMoreToQuery {
                print("Getting quests")
                if self.userCoordinate == nil {
                    try? await getUserLocation()
                }
                if let userCoordinate = self.userCoordinate {
                    let (newQuests, updatedQueriesWithLastDocuments)  = try await QuestManager.shared.getQuestsByProximity(queriesWithLastDocuments: queriesWithLastDocuments, count: 2, center: userCoordinate, radiusInM: 100000) // 100 km
                    if var newQuests = newQuests { // Checking for nil condition
                        for i in 0..<newQuests.count {
                            if let startLocation = newQuests[i].coordinateStart {
                                let latitude = startLocation.latitude
                                let longitude = startLocation.longitude
                                let questCLLocation = CLLocation(latitude: latitude, longitude: longitude)
                                let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
                                // Modify the quest's metaData
                                newQuests[i].metaData.distanceToUser = userLocation.distance(from: questCLLocation)
                            }
                        }
                        self.quests.append(contentsOf: newQuests)
                        print("Got quests")
                    }
                    // Filter out queries that should stop paginating
                    self.queriesWithLastDocuments = updatedQueriesWithLastDocuments.filter { queryWithLastDocument in
                        let (_, lastDocument) = queryWithLastDocument
                        return lastDocument != nil // Stop paginating if lastDocument is nil
                    }
                    
                    // Check if all queries are exhausted
                    if self.queriesWithLastDocuments.isEmpty {
                        print("All queries exhausted. No more quests to fetch.")
                        noMoreToQuery = true
                    }
                }
            }
            // GET QUESTS BY PROXIMITY END
        }
    }
    
    /*func getAllQuests() async throws {
        self.quests = try await QuestManager.shared.getAllQuests()
    }*/ // Works but not needed as it doesn't include pagination.
    
    func addUserWatchlistQuest(questId: String) {
        guard let user else { return } // Make sure the user is logged in or authenticated
        Task {
            // Add to relationship database
            try await UserQuestRelationshipManager.shared.addRelationship(userId: user.userId, questId: questId, relationshipType: .watchlist)
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
    }*/ // Works but not needed right now
    
}
