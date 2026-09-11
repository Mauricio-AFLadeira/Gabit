import Foundation

/// Owns the session for the login/register screens and everything after
/// them. The token lives in the Keychain (`TokenStore`); the user record is
/// small and non-sensitive, so it rides along in `UserDefaults` purely so a
/// relaunch can skip straight past the auth screens without an extra round
/// trip to `/auth/me`.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client: APIClient
    private static let userDefaultsKey = "com.mauricioafl.MauIt.authUser"

    var isAuthenticated: Bool { session != nil }

    init(client: APIClient = APIClient()) {
        self.client = client
        if let token = TokenStore.load(),
            let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
            let user = try? JSONDecoder().decode(AuthUser.self, from: data)
        {
            session = AuthSession(token: token, user: user)
        }
    }

    func register(name: String, email: String, password: String, phone: String?) async {
        await perform { try await client.register(name: name, email: email, password: password, phone: phone) }
    }

    func login(email: String, password: String) async {
        await perform { try await client.login(email: email, password: password) }
    }

    func clearError() {
        errorMessage = nil
    }

    func signOut() {
        TokenStore.clear()
        UserDefaults.standard.removeObject(forKey: Self.userDefaultsKey)
        session = nil
    }

    private func perform(_ makeRequest: () async throws -> AuthSession) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await makeRequest()
            TokenStore.save(session.token)
            if let data = try? JSONEncoder().encode(session.user) {
                UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
            }
            self.session = session
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
