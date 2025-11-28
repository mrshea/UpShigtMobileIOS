# iOS App Connection Issues - Solutions

## Problems Identified

### 1. ❌ Using `localhost` in iOS Simulator
**File:** `ApolloTest/Network.swift:7`
```swift
// ❌ WRONG - This won't work on iOS Simulator
private(set) lazy var apollo = ApolloClient(url: URL(string: "http://localhost:3000/api/graphql")!)
```

**Why it fails:** iOS Simulator can't resolve `localhost` the same way as your Mac.

**Solution:** Use `127.0.0.1` or your Mac's local IP address

### 2. ❌ Missing Authentication Headers
Your Network class doesn't add Clerk session tokens to GraphQL requests. The server requires authentication.

### 3. ❌ App Transport Security (ATS) Issue
Using `http://` instead of `https://` requires special configuration in Info.plist

### 4. ❌ View Models Not Implemented
`ShiftViewModel.swift` has empty TODO methods - no actual API calls are being made.

---

## Complete Fix

### Step 1: Update Network.swift

Replace the entire contents of `ApolloTest/Network.swift` with:

```swift
//
//  Network.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation
import Apollo
import ApolloAPI
import Clerk

class Network {
    static let shared = Network()

    private(set) lazy var apollo: ApolloClient = {
        // IMPORTANT: Use 127.0.0.1 for iOS Simulator
        // For physical device, use your Mac's IP: "http://192.168.1.XXX:3000/api/graphql"
        let url = URL(string: "http://127.0.0.1:3000/api/graphql")!

        let store = ApolloStore()

        let provider = AuthInterceptorProvider(
            store: store,
            client: URLSessionClient()
        )

        let networkTransport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: url
        )

        return ApolloClient(networkTransport: networkTransport, store: store)
    }()

    // Helper function to get Clerk session token
    func getSessionToken() async throws -> String? {
        guard let session = Clerk.shared.session else {
            print("⚠️ No active Clerk session")
            return nil
        }

        do {
            let token = try await session.getToken(.init(template: "default"))
            print("✅ Got Clerk session token: \(token.jwt.prefix(20))...")
            return token.jwt
        } catch {
            print("❌ Error getting session token: \(error)")
            throw error
        }
    }
}

// MARK: - Auth Interceptor

class AuthInterceptor: ApolloInterceptor {
    public var id: String = "AuthInterceptor"

    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation : ApolloAPI.GraphQLOperation {

        Task {
            do {
                if let token = try await Network.shared.getSessionToken() {
                    request.addHeader(name: "Authorization", value: "Bearer \(token)")
                    print("🔐 Added auth header to request")
                } else {
                    print("⚠️ No token available, proceeding without auth")
                }
            } catch {
                print("❌ Error in auth interceptor: \(error)")
            }

            chain.proceedAsync(
                request: request,
                response: response,
                interceptor: self,
                completion: completion
            )
        }
    }
}

// MARK: - Auth Interceptor Provider

class AuthInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : ApolloAPI.GraphQLOperation {
        var interceptors = super.interceptors(for: operation)
        // Insert auth interceptor before the network fetch
        interceptors.insert(AuthInterceptor(), at: 0)
        return interceptors
    }
}
```

### Step 2: Configure App Transport Security

Create or update `UpShiftMobile/Info.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Allow HTTP connections to localhost for development -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
            <key>127.0.0.1</key>
            <dict>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

**Alternative:** If you have a target settings approach, add this to your `Info` in Xcode:
1. Select your project target
2. Go to Info tab
3. Add `App Transport Security Settings` (Dictionary)
4. Add `Allow Arbitrary Loads in Web Content` (Boolean) = YES
5. Add `Allow Local Networking` (Boolean) = YES

### Step 3: Implement ShiftViewModel

Update `UpShiftMobile/MySchedule/ShiftViewModel.swift`:

```swift
import Foundation
import Combine
import UpShiftAPI // Your generated Apollo API

@MainActor
class ShiftViewModel: ObservableObject {
    @Published var shifts: [Shift] = []
    @Published var myShifts: [MyShiftClaim] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Fetch All Shifts

    func fetchShifts(startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        let query = GetShiftsQuery(startDate: startDate, endDate: endDate)

        do {
            let result = try await Network.shared.apollo.fetch(query: query)

            if let errors = result.errors {
                errorMessage = errors.map { $0.message }.joined(separator: "\n")
                print("❌ GraphQL errors: \(errors)")
            }

            if let shiftsData = result.data?.shifts {
                // Map GraphQL data to your local models
                shifts = shiftsData.compactMap { shift in
                    guard let date = ISO8601DateFormatter().date(from: shift.date) else {
                        return nil
                    }
                    return Shift(
                        id: shift.id,
                        date: date,
                        startTime: shift.startTime,
                        endTime: shift.endTime,
                        peopleNeeded: shift.peopleNeeded,
                        role: shift.role,
                        availableSpots: shift.availableSpots,
                        claimedBy: []
                    )
                }
                print("✅ Fetched \(shifts.count) shifts")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error fetching shifts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Fetch My Shifts

    func fetchMyShifts() async {
        isLoading = true
        errorMessage = nil

        let query = GetMyShiftsQuery()

        do {
            let result = try await Network.shared.apollo.fetch(query: query)

            if let errors = result.errors {
                errorMessage = errors.map { $0.message }.joined(separator: "\n")
                print("❌ GraphQL errors: \(errors)")
            }

            if let myShiftsData = result.data?.myShifts {
                // Map to your local models
                myShifts = myShiftsData.compactMap { claim in
                    guard let shiftDate = ISO8601DateFormatter().date(from: claim.shift.date),
                          let claimedAt = ISO8601DateFormatter().date(from: claim.claimedAt) else {
                        return nil
                    }

                    let shift = Shift(
                        id: claim.shift.id,
                        date: shiftDate,
                        startTime: claim.shift.startTime,
                        endTime: claim.shift.endTime,
                        peopleNeeded: 0,
                        role: claim.shift.role,
                        availableSpots: 0,
                        claimedBy: []
                    )

                    return MyShiftClaim(
                        id: claim.id,
                        shiftId: claim.shiftId,
                        shift: shift,
                        claimedAt: claimedAt
                    )
                }
                print("✅ Fetched \(myShifts.count) claimed shifts")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error fetching my shifts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Claim Shift

    func claimShift(shiftId: String) async throws {
        let mutation = ClaimShiftMutation(shiftId: shiftId)

        let result = try await Network.shared.apollo.perform(mutation: mutation)

        if let errors = result.errors {
            let errorMessage = errors.map { $0.message }.joined(separator: "\n")
            print("❌ GraphQL errors: \(errorMessage)")
            throw NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        print("✅ Successfully claimed shift: \(shiftId)")

        // Refresh shifts
        await fetchMyShifts()
    }

    // MARK: - Unclaim Shift

    func unclaimShift(shiftId: String) async throws {
        let mutation = UnclaimShiftMutation(shiftId: shiftId)

        let result = try await Network.shared.apollo.perform(mutation: mutation)

        if let errors = result.errors {
            let errorMessage = errors.map { $0.message }.joined(separator: "\n")
            print("❌ GraphQL errors: \(errorMessage)")
            throw NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        print("✅ Successfully unclaimed shift: \(shiftId)")

        // Refresh shifts
        await fetchMyShifts()
    }

    // MARK: - Helper Methods

    func shiftsForDate(_ date: Date) -> [Shift] {
        let calendar = Calendar.current
        return shifts.filter { shift in
            calendar.isDate(shift.date, inSameDayAs: date)
        }
    }

    func myShiftsForDate(_ date: Date) -> [MyShiftClaim] {
        let calendar = Calendar.current
        return myShifts.filter { claim in
            calendar.isDate(claim.shift.date, inSameDayAs: date)
        }
    }
}
```

### Step 4: Testing Steps

1. **Start your Next.js server:**
```bash
cd /Users/michaelshea/Desktop/DEV/upshiftbackend
npm run dev
```

2. **Verify server is running:**
   - Open browser to `http://localhost:3000/api/graphql`
   - You should see Apollo Studio Sandbox

3. **Find your Mac's IP address (for physical device testing):**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
   - Look for something like `192.168.1.XXX`

4. **Update URL in Network.swift if testing on physical device:**
```swift
let url = URL(string: "http://192.168.1.XXX:3000/api/graphql")!
```

5. **Clean and rebuild your iOS app:**
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)
   - Run the app

6. **Check console logs:**
   - Look for: `✅ Got Clerk session token`
   - Look for: `🔐 Added auth header to request`
   - Look for: `✅ Fetched X shifts`

### Step 5: Debugging Tips

**If you see authentication errors:**
- Make sure you're signed in with Clerk
- Check console for: `⚠️ No active Clerk session`
- Verify the Clerk publishable key is correct

**If you see connection errors:**
- Verify Next.js server is running (`npm run dev`)
- Test the endpoint in browser: `http://127.0.0.1:3000/api/graphql`
- Check your Mac's firewall settings

**If using physical device:**
- Mac and iPhone must be on same WiFi network
- Use Mac's local IP address, not `127.0.0.1`
- Firewall may block incoming connections - temporarily disable to test

**Common error messages:**
- `UNAUTHENTICATED` = No auth token or invalid token
- `FORBIDDEN` = User doesn't have permission (admin-only mutation)
- `Connection refused` = Server not running or wrong URL
- `NSURLError` = Network connectivity issue

### Quick Test Query

Add this to test your connection:

```swift
// In any view or view model
Task {
    do {
        let query = GetShiftsQuery(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7)
        )
        let result = try await Network.shared.apollo.fetch(query: query)
        print("✅ Connection successful! Shifts: \(result.data?.shifts?.count ?? 0)")
    } catch {
        print("❌ Connection failed: \(error)")
    }
}
```

## Summary of Changes

1. ✅ Changed URL from `localhost` to `127.0.0.1`
2. ✅ Added Clerk authentication interceptor
3. ✅ Configured App Transport Security for HTTP
4. ✅ Implemented ShiftViewModel with real API calls
5. ✅ Added comprehensive error logging

Your iOS app should now successfully connect to your GraphQL backend!
