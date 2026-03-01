import Foundation

struct SupabaseConfig {
    let baseURL: URL
    let anonKey: String
    let authToken: String?
    let userID: UUID
    let displayName: String

    static func load(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) -> SupabaseConfig? {
        let resolvedBaseURL = defaults.string(forKey: AppGroupDefaults.supabaseURL) ?? AppGroupDefaults.defaultSupabaseURL
        let resolvedAnonKey = defaults.string(forKey: AppGroupDefaults.supabaseAnonKey) ?? AppGroupDefaults.defaultSupabaseAnonKey

        guard let url = URL(string: resolvedBaseURL),
              !resolvedAnonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let displayName = defaults.string(forKey: AppGroupDefaults.localDisplayName) ?? "You"
        return SupabaseConfig(
            baseURL: url,
            anonKey: resolvedAnonKey,
            authToken: defaults.string(forKey: AppGroupDefaults.supabaseAuthToken),
            userID: AppGroupDefaults.ensureLocalUserID(defaults: defaults),
            displayName: displayName
        )
    }
}

final class SupabaseBuddyService: BuddyProviding {
    private struct DailyBorrowLimitRow: Codable {
        let userID: UUID
        let dayKey: String
        var approvalsUsed: Int

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case dayKey = "day_key"
            case approvalsUsed = "approvals_used"
        }
    }

    private struct PostgrestErrorPayload: Decodable {
        let message: String?
        let details: String?
        let hint: String?
        let code: String?
    }

    private let config: SupabaseConfig
    private let defaults: UserDefaults
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        config: SupabaseConfig,
        defaults: UserDefaults = AppGroupDefaults.sharedDefaults,
        session: URLSession = .shared
    ) {
        self.config = config
        self.defaults = defaults
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if let value = Self.iso8601WithFractionalSeconds.date(from: raw) ?? Self.iso8601.date(from: raw) {
                return value
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format: \(raw)")
        }
        self.decoder = decoder
    }

    func fetchMyProfile() async throws -> BuddyProfile {
        if let profile = try await fetchProfile(id: config.userID) {
            syncCaches(from: profile)
            return profile
        }

        let created = try await createProfile()
        syncCaches(from: created)
        return created
    }

    func pairWithInviteCode(_ code: String) async throws -> BuddyProfile {
        let me = try await fetchMyProfile()

        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalized.isEmpty else {
            throw BuddyServiceError.invalidInviteCode
        }

        guard let buddy = try await fetchProfile(byInviteCode: normalized), buddy.id != me.id else {
            throw BuddyServiceError.invalidInviteCode
        }

        _ = try await patchProfile(id: me.id, fields: ["buddy_id": buddy.id.uuidString])
        _ = try await patchProfile(id: buddy.id, fields: ["buddy_id": me.id.uuidString])

        var updated = try await fetchMyProfile()
        updated.buddyDisplayName = buddy.displayName
        return updated
    }

    func createBorrowRequest(minutes: Int, note: String?) async throws -> BorrowRequest {
        let draft = BorrowRequestDraft(minutes: minutes, note: note ?? "")
        try draft.validate()

        let me = try await fetchMyProfile()
        guard let buddyID = me.buddyID else {
            throw BuddyServiceError.notPaired
        }

        if try await fetchLatestOutgoingPendingRequest() != nil {
            throw BuddyServiceError.outgoingRequestAlreadyPending
        }

        let approvalsUsed = try await fetchApprovalsUsedToday()
        if approvalsUsed >= 2 {
            throw BuddyServiceError.dailyApprovalCapReached
        }

        let now = Date()
        var payload: [String: Any] = [
            "requester_id": me.id.uuidString,
            "buddy_id": buddyID.uuidString,
            "minutes_requested": minutes,
            "status": BorrowRequestStatus.pending.rawValue,
            "created_at": Self.iso8601WithFractionalSeconds.string(from: now),
            "expires_at": Self.iso8601WithFractionalSeconds.string(from: now.addingTimeInterval(15 * 60))
        ]
        payload["note"] = draft.normalizedNote ?? NSNull()

        let data = try await perform(
            method: "POST",
            path: "borrow_requests",
            query: [],
            body: payload,
            prefer: "return=representation"
        )

        let created = try decode([BorrowRequest].self, from: data).first
        guard var request = created else {
            throw BuddyServiceError.server("Could not create request.")
        }

        request.requesterDisplayName = me.displayName
        request.buddyDisplayName = me.buddyDisplayName
        return request
    }

    func fetchLatestIncomingPendingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()
        let now = Self.iso8601WithFractionalSeconds.string(from: Date())

        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,requester_id,buddy_id,minutes_requested,note,status,created_at,resolved_at,expires_at"),
            URLQueryItem(name: "buddy_id", value: "eq.\(me.id.uuidString)"),
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "expires_at", value: "gt.\(now)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "borrow_requests", query: query)
        guard var request = try decode([BorrowRequest].self, from: data).first else {
            return nil
        }

        request.requesterDisplayName = try await fetchDisplayName(for: request.requesterID)
        request.buddyDisplayName = me.displayName
        return request
    }

    func fetchLatestOutgoingPendingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()
        let now = Self.iso8601WithFractionalSeconds.string(from: Date())

        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,requester_id,buddy_id,minutes_requested,note,status,created_at,resolved_at,expires_at"),
            URLQueryItem(name: "requester_id", value: "eq.\(me.id.uuidString)"),
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "expires_at", value: "gt.\(now)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "borrow_requests", query: query)
        guard var request = try decode([BorrowRequest].self, from: data).first else {
            return nil
        }

        request.requesterDisplayName = me.displayName
        request.buddyDisplayName = try await fetchDisplayName(for: request.buddyID)
        return request
    }

    func fetchLatestOutgoingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()

        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,requester_id,buddy_id,minutes_requested,note,status,created_at,resolved_at,expires_at"),
            URLQueryItem(name: "requester_id", value: "eq.\(me.id.uuidString)"),
            URLQueryItem(name: "status", value: "in.(pending,approved,denied,expired,consumed)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "borrow_requests", query: query)
        guard var request = try decode([BorrowRequest].self, from: data).first else {
            return nil
        }

        request.requesterDisplayName = me.displayName
        request.buddyDisplayName = try await fetchDisplayName(for: request.buddyID)
        return request
    }

    func observeLatestIncomingPendingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        observe(poll: fetchLatestIncomingPendingRequest)
    }

    func observeLatestOutgoingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        observe(poll: fetchLatestOutgoingRequest)
    }

    func resolveRequest(id: UUID, decision: BorrowRequestDecision) async throws -> BorrowRequest {
        let me = try await fetchMyProfile()

        guard let current = try await fetchRequest(id: id) else {
            throw BuddyServiceError.server("Request not found.")
        }

        guard current.buddyID == me.id else {
            throw BuddyServiceError.forbidden
        }

        guard current.status == .pending else {
            throw BuddyServiceError.server("Request has already been resolved.")
        }

        if current.expiresAt <= Date() {
            _ = try await patchRequestStatus(id: current.id, status: .expired)
            throw BuddyServiceError.requestExpired
        }

        if decision == .approve {
            let used = try await approvalsUsedToday(for: current.requesterID)
            if used >= 2 {
                throw BuddyServiceError.dailyApprovalCapReached
            }
        }

        var updated = try await patchRequestStatus(id: current.id, status: decision.resultingStatus)

        if decision == .approve {
            try await incrementApprovalsUsed(for: current.requesterID)
            try await applyApprovalEffects(requesterID: current.requesterID, buddyID: current.buddyID)
        }

        updated.requesterDisplayName = try await fetchDisplayName(for: updated.requesterID)
        updated.buddyDisplayName = me.displayName
        return updated
    }

    func fetchApprovalsUsedToday() async throws -> Int {
        try await approvalsUsedToday(for: config.userID)
    }

    private func observe(poll: @escaping () async throws -> BorrowRequest?) -> AsyncStream<Result<BorrowRequest?, Error>> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    do {
                        continuation.yield(.success(try await poll()))
                    } catch {
                        continuation.yield(.failure(error))
                    }

                    try? await Task.sleep(for: .seconds(3))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func createProfile() async throws -> BuddyProfile {
        let inviteCode = defaults.string(forKey: AppGroupDefaults.localInviteCode) ?? Self.generateInviteCode()

        let payload: [String: Any] = [
            "id": config.userID.uuidString,
            "display_name": config.displayName,
            "invite_code": inviteCode,
            "points": AppGroupDefaults.cachedPointsValue(defaults: defaults),
            "health": AppGroupDefaults.cachedHealthValue(defaults: defaults)
        ]

        let data = try await perform(
            method: "POST",
            path: "profiles",
            query: [],
            body: payload,
            prefer: "return=representation"
        )

        guard let profile = try decode([BuddyProfile].self, from: data).first else {
            throw BuddyServiceError.server("Could not create profile.")
        }

        defaults.set(inviteCode, forKey: AppGroupDefaults.localInviteCode)
        return profile
    }

    private func fetchProfile(id: UUID) async throws -> BuddyProfile? {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,display_name,invite_code,buddy_id,points,health"),
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "profiles", query: query)
        return try decode([BuddyProfile].self, from: data).first
    }

    private func fetchProfile(byInviteCode code: String) async throws -> BuddyProfile? {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,display_name,invite_code,buddy_id,points,health"),
            URLQueryItem(name: "invite_code", value: "eq.\(code)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "profiles", query: query)
        return try decode([BuddyProfile].self, from: data).first
    }

    @discardableResult
    private func patchProfile(id: UUID, fields: [String: Any]) async throws -> BuddyProfile {
        let query = [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]
        let data = try await perform(
            method: "PATCH",
            path: "profiles",
            query: query,
            body: fields,
            prefer: "return=representation"
        )

        guard let profile = try decode([BuddyProfile].self, from: data).first else {
            throw BuddyServiceError.server("Could not update profile.")
        }

        syncCaches(from: profile)
        return profile
    }

    private func fetchRequest(id: UUID) async throws -> BorrowRequest? {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,requester_id,buddy_id,minutes_requested,note,status,created_at,resolved_at,expires_at"),
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "borrow_requests", query: query)
        return try decode([BorrowRequest].self, from: data).first
    }

    private func patchRequestStatus(id: UUID, status: BorrowRequestStatus) async throws -> BorrowRequest {
        let now = Self.iso8601WithFractionalSeconds.string(from: Date())
        let body: [String: Any] = [
            "status": status.rawValue,
            "resolved_at": now
        ]

        let query: [URLQueryItem] = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
            URLQueryItem(name: "status", value: "eq.pending")
        ]

        let data = try await perform(
            method: "PATCH",
            path: "borrow_requests",
            query: query,
            body: body,
            prefer: "return=representation"
        )

        guard let request = try decode([BorrowRequest].self, from: data).first else {
            throw BuddyServiceError.server("Could not update request.")
        }

        return request
    }

    private func approvalsUsedToday(for userID: UUID) async throws -> Int {
        let dayKey = Self.dayKey(for: Date())

        let query: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "user_id,day_key,approvals_used"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "day_key", value: "eq.\(dayKey)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let data = try await perform(method: "GET", path: "daily_borrow_limits", query: query)
        return try decode([DailyBorrowLimitRow].self, from: data).first?.approvalsUsed ?? 0
    }

    private func incrementApprovalsUsed(for userID: UUID) async throws {
        let dayKey = Self.dayKey(for: Date())
        let current = try await approvalsUsedToday(for: userID)

        if current >= 2 {
            throw BuddyServiceError.dailyApprovalCapReached
        }

        let next = current + 1

        if current == 0 {
            let body: [String: Any] = [
                "user_id": userID.uuidString,
                "day_key": dayKey,
                "approvals_used": next
            ]

            _ = try await perform(
                method: "POST",
                path: "daily_borrow_limits",
                query: [URLQueryItem(name: "on_conflict", value: "user_id,day_key")],
                body: body,
                prefer: "return=representation,resolution=merge-duplicates"
            )
        } else {
            let body: [String: Any] = ["approvals_used": next]
            let query: [URLQueryItem] = [
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
                URLQueryItem(name: "day_key", value: "eq.\(dayKey)")
            ]

            _ = try await perform(
                method: "PATCH",
                path: "daily_borrow_limits",
                query: query,
                body: body,
                prefer: "return=representation"
            )
        }
    }

    private func applyApprovalEffects(requesterID: UUID, buddyID: UUID) async throws {
        if var requester = try await fetchProfile(id: requesterID) {
            requester.health = max(0, requester.health - 5)
            _ = try await patchProfile(id: requester.id, fields: ["health": requester.health])

            if requesterID == config.userID {
                AppGroupDefaults.setCachedHealthValue(requester.health, defaults: defaults)
            }
        }

        if var buddy = try await fetchProfile(id: buddyID) {
            buddy.points += 10
            _ = try await patchProfile(id: buddy.id, fields: ["points": buddy.points])

            if buddyID == config.userID {
                AppGroupDefaults.setCachedPointsValue(buddy.points, defaults: defaults)
            }
        }
    }

    private func fetchDisplayName(for userID: UUID) async throws -> String? {
        try await fetchProfile(id: userID)?.displayName
    }

    private func syncCaches(from profile: BuddyProfile) {
        defaults.set(profile.displayName, forKey: AppGroupDefaults.localDisplayName)
        defaults.set(profile.inviteCode, forKey: AppGroupDefaults.localInviteCode)
        AppGroupDefaults.setCachedHealthValue(profile.health, defaults: defaults)
        AppGroupDefaults.setCachedPointsValue(profile.points, defaults: defaults)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw BuddyServiceError.server("Could not decode server response.")
        }
    }

    private func perform(
        method: String,
        path: String,
        query: [URLQueryItem],
        body: [String: Any]? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        guard var components = URLComponents(url: config.baseURL.appendingPathComponent("rest/v1/\(path)"), resolvingAgainstBaseURL: false) else {
            throw BuddyServiceError.missingConfiguration
        }

        if !query.isEmpty {
            components.queryItems = query
        }

        guard let url = components.url else {
            throw BuddyServiceError.missingConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.authToken ?? config.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BuddyServiceError.server("Invalid server response.")
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw BuddyServiceError.forbidden
            }

            let payload = try? JSONDecoder().decode(PostgrestErrorPayload.self, from: data)
            let message = payload?.message ?? payload?.details ?? "Server error (\(http.statusCode))."
            throw BuddyServiceError.server(message)
        }

        return data
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func generateInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in alphabet.randomElement() })
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
