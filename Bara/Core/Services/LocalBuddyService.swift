import Foundation

final class LocalBuddyService: BuddyProviding {
    private enum DefaultsKey {
        static let profile = "bara.localbuddy.profile"
        static let requests = "bara.localbuddy.requests"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) {
        self.defaults = defaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchMyProfile() async throws -> BuddyProfile {
        if let data = defaults.data(forKey: DefaultsKey.profile), let profile = try? decoder.decode(BuddyProfile.self, from: data) {
            syncLocalCaches(from: profile)
            return profile
        }

        let profile = BuddyProfile(
            id: AppGroupDefaults.ensureLocalUserID(defaults: defaults),
            displayName: defaults.string(forKey: AppGroupDefaults.localDisplayName) ?? "You",
            inviteCode: defaults.string(forKey: AppGroupDefaults.localInviteCode) ?? Self.generateInviteCode(),
            buddyID: nil,
            points: AppGroupDefaults.cachedPointsValue(defaults: defaults),
            health: AppGroupDefaults.cachedHealthValue(defaults: defaults),
            buddyDisplayName: nil
        )

        saveProfile(profile)
        defaults.set(profile.inviteCode, forKey: AppGroupDefaults.localInviteCode)
        return profile
    }

    func pairWithInviteCode(_ code: String) async throws -> BuddyProfile {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else {
            throw BuddyServiceError.invalidInviteCode
        }

        var profile = try await fetchMyProfile()
        profile.buddyID = Self.uuid(fromInviteCode: normalized)
        profile.buddyDisplayName = "Friend"
        saveProfile(profile)
        return profile
    }

    func unpairCurrentBuddy() async throws -> BuddyProfile {
        var profile = try await fetchMyProfile()
        guard let buddyID = profile.buddyID else {
            throw BuddyServiceError.alreadyUnpaired
        }

        profile.buddyID = nil
        profile.buddyDisplayName = nil
        profile.inviteCode = Self.generateInviteCode()

        var requests = loadRequests()
        expirePairPendingRequestsIfNeeded(&requests, meID: profile.id, buddyID: buddyID)
        saveRequests(requests)
        saveProfile(profile)
        return profile
    }

    func resetDemoState() async throws -> BuddyProfile {
        var profile = try await fetchMyProfile()

        if profile.isPaired {
            profile = try await unpairCurrentBuddy()
        }

        profile.health = 100
        profile.points = 0
        profile.buddyID = nil
        profile.buddyDisplayName = nil
        profile.inviteCode = Self.generateInviteCode()

        defaults.removeObject(forKey: DefaultsKey.requests)
        saveProfile(profile)

        AppGroupDefaults.clearBorrowAndBlockFlags(defaults: defaults)
        AppGroupDefaults.clearFocusSetup(defaults: defaults)
        AppGroupDefaults.markOnboardingIncomplete(defaults: defaults)

        return profile
    }

    func createBorrowRequest(minutes: Int, note: String?) async throws -> BorrowRequest {
        var profile = try await fetchMyProfile()
        guard let buddyID = profile.buddyID else {
            throw BuddyServiceError.notPaired
        }

        let draft = BorrowRequestDraft(minutes: minutes, note: note ?? "")
        try draft.validate()

        if try await fetchLatestOutgoingPendingRequest() != nil {
            throw BuddyServiceError.outgoingRequestAlreadyPending
        }

        let now = Date()
        let request = BorrowRequest(
            id: UUID(),
            requesterID: profile.id,
            buddyID: buddyID,
            minutesRequested: minutes,
            note: draft.normalizedNote,
            status: .pending,
            createdAt: now,
            resolvedAt: nil,
            expiresAt: now.addingTimeInterval(15 * 60),
            requesterDisplayName: profile.displayName,
            buddyDisplayName: profile.buddyDisplayName
        )

        var requests = loadRequests()
        requests.append(request)
        saveRequests(requests)

        profile.health = AppGroupDefaults.cachedHealthValue(defaults: defaults)
        saveProfile(profile)
        return request
    }

    func fetchLatestIncomingPendingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()
        var requests = loadRequests()
        expirePendingRequestsIfNeeded(&requests)
        saveRequests(requests)

        return requests
            .filter { $0.buddyID == me.id && $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func fetchLatestOutgoingPendingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()
        var requests = loadRequests()
        expirePendingRequestsIfNeeded(&requests)
        saveRequests(requests)

        return requests
            .filter { $0.requesterID == me.id && $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func fetchLatestOutgoingRequest() async throws -> BorrowRequest? {
        let me = try await fetchMyProfile()
        var requests = loadRequests()
        expirePendingRequestsIfNeeded(&requests)
        saveRequests(requests)

        return requests
            .filter { $0.requesterID == me.id }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func observeLatestIncomingPendingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        observe(poll: fetchLatestIncomingPendingRequest)
    }

    func observeLatestOutgoingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        observe(poll: fetchLatestOutgoingRequest)
    }

    func resolveRequest(id: UUID, decision: BorrowRequestDecision) async throws -> BorrowRequest {
        let me = try await fetchMyProfile()
        var requests = loadRequests()
        expirePendingRequestsIfNeeded(&requests)

        guard let index = requests.firstIndex(where: { $0.id == id }) else {
            throw BuddyServiceError.server("Request not found.")
        }

        let request = requests[index]
        guard request.buddyID == me.id else {
            throw BuddyServiceError.forbidden
        }

        guard request.status == .pending else {
            if request.isExpired {
                throw BuddyServiceError.requestExpired
            }
            throw BuddyServiceError.server("Request has already been resolved.")
        }

        if request.expiresAt <= Date() {
            requests[index] = update(request: request, status: .expired, resolvedAt: Date())
            saveRequests(requests)
            throw BuddyServiceError.requestExpired
        }

        let now = Date()
        let updated = update(request: request, status: decision.resultingStatus, resolvedAt: now)
        requests[index] = updated

        if decision == .approve {
            let healthPenalty = AppGroupDefaults.borrowApprovalRequesterHealthPenalty(for: request.minutesRequested)
            var meUpdated = me
            meUpdated.points += AppGroupDefaults.borrowApprovalBuddyPointsReward
            saveProfile(meUpdated)
            AppGroupDefaults.setCachedPointsValue(meUpdated.points, defaults: defaults)

            if request.requesterID == meUpdated.id {
                let nextPoints = max(0, meUpdated.points - AppGroupDefaults.borrowApprovalRequesterPointsPenalty)
                meUpdated.points = nextPoints
                let nextHealth = max(0, meUpdated.health - healthPenalty)
                meUpdated.health = nextHealth
                saveProfile(meUpdated)
                AppGroupDefaults.setCachedHealthValue(nextHealth, defaults: defaults)
                AppGroupDefaults.setCachedPointsValue(nextPoints, defaults: defaults)
            }
        }

        saveRequests(requests)
        return updated
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

    private func loadRequests() -> [BorrowRequest] {
        guard let data = defaults.data(forKey: DefaultsKey.requests),
              let decoded = try? decoder.decode([BorrowRequest].self, from: data) else {
            return []
        }

        return decoded
    }

    private func saveRequests(_ requests: [BorrowRequest]) {
        guard let encoded = try? encoder.encode(requests) else {
            return
        }
        defaults.set(encoded, forKey: DefaultsKey.requests)
    }

    private func saveProfile(_ profile: BuddyProfile) {
        guard let encoded = try? encoder.encode(profile) else {
            return
        }

        defaults.set(encoded, forKey: DefaultsKey.profile)
        defaults.set(profile.displayName, forKey: AppGroupDefaults.localDisplayName)
        defaults.set(profile.inviteCode, forKey: AppGroupDefaults.localInviteCode)
        AppGroupDefaults.setCachedHealthValue(profile.health, defaults: defaults)
        AppGroupDefaults.setCachedPointsValue(profile.points, defaults: defaults)
    }

    private func expirePendingRequestsIfNeeded(_ requests: inout [BorrowRequest]) {
        let now = Date()

        requests = requests.map { request in
            guard request.status == .pending, request.expiresAt <= now else {
                return request
            }
            return update(request: request, status: .expired, resolvedAt: now)
        }
    }

    private func expirePairPendingRequestsIfNeeded(_ requests: inout [BorrowRequest], meID: UUID, buddyID: UUID) {
        let now = Date()

        requests = requests.map { request in
            guard request.status == .pending else {
                return request
            }

            let isOutgoing = request.requesterID == meID && request.buddyID == buddyID
            let isIncoming = request.requesterID == buddyID && request.buddyID == meID

            guard isOutgoing || isIncoming else {
                return request
            }

            return update(request: request, status: .expired, resolvedAt: now)
        }
    }

    private func update(request: BorrowRequest, status: BorrowRequestStatus, resolvedAt: Date?) -> BorrowRequest {
        BorrowRequest(
            id: request.id,
            requesterID: request.requesterID,
            buddyID: request.buddyID,
            minutesRequested: request.minutesRequested,
            note: request.note,
            status: status,
            createdAt: request.createdAt,
            resolvedAt: resolvedAt,
            expiresAt: request.expiresAt,
            requesterDisplayName: request.requesterDisplayName,
            buddyDisplayName: request.buddyDisplayName
        )
    }

    private func syncLocalCaches(from profile: BuddyProfile) {
        AppGroupDefaults.setCachedHealthValue(profile.health, defaults: defaults)
        AppGroupDefaults.setCachedPointsValue(profile.points, defaults: defaults)
    }

    private static func generateInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in alphabet.randomElement() })
    }

    private static func uuid(fromInviteCode code: String) -> UUID {
        var accumulator: UInt64 = 0
        for byte in code.utf8 {
            accumulator = (accumulator &* 131 &+ UInt64(byte)) % 0xFFFFFFFFFFFF
        }
        let hex = String(format: "%012llX", accumulator)
        return UUID(uuidString: "00000000-0000-4000-8000-\(hex)") ?? UUID()
    }
}
