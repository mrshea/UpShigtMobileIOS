import Foundation
import Apollo

class Network {
    static let shared = Network()

    private(set) lazy var apollo = ApolloClient(url: URL(string: "http://localhost:3000/api/graphql")!)
}//
//  Network.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation
