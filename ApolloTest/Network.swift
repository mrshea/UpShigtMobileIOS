import Foundation
import Apollo
import ApolloAPI

class Network {
    static let shared = Network()
    
    private let store = ApolloStore()

    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "http://192.168.1.82:3000/api/graphql")!
        
        // Create the network transport with the authorization interceptor
        let provider = NetworkInterceptorProvider()
        
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: provider,
            store: store,
            endpointURL: url
        )
        
        return ApolloClient(networkTransport: transport, store: store)
    }()
}

// Custom interceptor provider that adds our authorization interceptor
struct NetworkInterceptorProvider: InterceptorProvider {
    
    func httpInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any HTTPInterceptor] {
        return [
            AuthorizationInterceptor(),  // Add our custom auth interceptor
            ResponseCodeInterceptor()    // Default response code interceptor
        ]
    }
}



import Foundation
import Apollo
import ApolloAPI
import Clerk

struct AuthorizationInterceptor: HTTPInterceptor {
    func intercept(
      request: URLRequest,
      next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        var request = request
        
        // Get the Clerk session token
        if let session = await Clerk.shared.session {
            do {
                if let tokenResource = try await session.getToken() {
                    // Add the JWT as a Bearer token to the Authorization header
                    request.addValue("Bearer \(tokenResource.jwt)", forHTTPHeaderField: "Authorization")
                }
            } catch {
                // Log the error but continue with the request
                print("Failed to get Clerk token: \(error)")
            }
        }
        
        return try await next(request)
    }
}
