//
//  Query+EXT.swift
//  Quests
//
//  Created by Jack Buhler on 2024-12-29.
//

import Foundation
import Combine
import FirebaseFirestore

extension Query { // Extension of questCollection's parent type (Collection Reference) (self == questCollection)
    
    /*func getDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable { // T is a "generic" that can represent any type
        // Access the entire quests collection
        let snapshot = try await self.getDocuments()
        print("Snapshot contains \(snapshot.documents.count) documents.")
        // ORIGINAL CODE:
        /*return try snapshot.documents.map({ document in
            try document.data(as: T.self)
        }) */
        return try snapshot.documents.map { document in
             do {
                 let decodedData = try document.data(as: T.self)
                 // Debug: Print successfully decoded data
                 print("Successfully decoded document with ID \(document.documentID): \(decodedData)")
                 return decodedData
             } catch {
                 // Debug: Print error and document details
                 print("Error decoding document with ID \(document.documentID): \(error.localizedDescription)")
                 throw error
             }
         }

    } */
    
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable {
        try await getDocumentsWithSnapshot(as: type).quests
    }
    
    func getDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (quests: [T], lastDocument: DocumentSnapshot?) where T : Decodable { // T is a "generic" that can represent any type
        // Access the entire quests collection
        let snapshot = try await self.getDocuments()
        print("Snapshot contains \(snapshot.documents.count) documents.")
        let quests = try snapshot.documents.map({ document in
            try document.data(as: T.self)
        })

        return (quests, snapshot.documents.last)
    }
    
    // .start(afterDocument: lastDocument)
    func startOptionally(afterDocument lastDocument: DocumentSnapshot?) -> Query {
        guard let lastDocument else {
            return self
        }
        return self.start(afterDocument: lastDocument)
    }
    
    func addSnapshotListener<T>(as type: T.Type) -> (AnyPublisher<[T], Error>, ListenerRegistration) where T : Decodable {
        // Create publisher and return it. Quests discovered by the listener are returned to the app through to the previously returned publisher
        // Just listen to publisher on the view
        let publisher = PassthroughSubject<[T], Error>() // No starting value
        
        let listener = self.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            let entries: [T] = documents.compactMap { documentSnapshot in
                return try? documentSnapshot.data(as: T.self)
            }
            publisher.send(entries)
        }
        
        return (publisher.eraseToAnyPublisher(), listener) // Any publisher type with the listener reference in case we need to close it
    }
    
}
