import Foundation

typealias GameId = UUID
typealias PlayerId = UUID

enum Move {
    case rock
    case paper
    case scissors
    
    func beats(move: Move) -> Bool {
        switch (self, move) {
        case (.rock, .scissors): return true
        case (.paper, .rock): return true
        case (.scissors, .paper): return true
        default: return false
        }
    }
}

struct PlayerMove {
    let playerId: PlayerId
    let move: Move
}

enum GameResult {
    case won(PlayerId)
    case tied
}

enum GameProgress {
    case uninitialized
    case notStarted
    case firstMoveMade(PlayerMove)
    case gameEnded(GameResult)
}

struct GameState {
    let gameId: GameId
    let gameProgress: GameProgress
}

enum Command {
    case createGame(GameId, PlayerId)
    case play(GameId, PlayerId, Move)
}

protocol DomainEvent {
    var gameId: GameId { get }
}

struct GameCreated: DomainEvent, Equatable {
    let gameId: GameId
    let createdBy: PlayerId
}

struct MoveMade: DomainEvent, Equatable {
    let gameId: GameId
    let playerId: PlayerId
    let move: Move
}

struct GameWon: DomainEvent, Equatable {
    let gameId: GameId
    let winnerId: PlayerId
}

struct GameTied: DomainEvent, Equatable {
    let gameId: GameId
}

struct RecreateGameState {
    private static func apply(state: GameState, event: DomainEvent) -> GameState {
        switch event {
        case let e as GameCreated:
            return GameState(gameId: e.gameId, gameProgress: .notStarted)
        case let e as MoveMade:
            switch state.gameProgress {
            case .notStarted:
                return GameState(gameId: e.gameId, gameProgress: .firstMoveMade(PlayerMove(playerId: e.playerId, move: e.move)))
            default:
                return state
            }
        case let e as GameWon:
            switch state.gameProgress {
            case .firstMoveMade:
                return GameState(gameId: e.gameId, gameProgress: .gameEnded(.won(e.winnerId)))
            default:
                return state
            }
        case let e as GameTied:
            switch state.gameProgress {
            case .firstMoveMade:
                return GameState(gameId: e.gameId, gameProgress: .gameEnded(.tied))
            default:
                return state
            }
        default:
            return state
        }
    }
    
    static func recreateGameStateFrom(events: [DomainEvent]) -> GameState {
        let initialState = GameState(gameId: GameId(), gameProgress: .uninitialized)
        return events.reduce(initialState, apply(state:event:))
    }
}

struct Game {
    private static func createGame(state: GameState, gameId: GameId, createdBy: PlayerId) -> [DomainEvent] {
        switch state.gameProgress {
        case .uninitialized:
            return [GameCreated(gameId: gameId, createdBy: createdBy)]
        default:
            return []
        }
    }
    
    private static func play(state: GameState, playerId: PlayerId, move: Move) -> [DomainEvent] {
        switch state.gameProgress {
        case .notStarted:
            return [MoveMade(gameId: state.gameId, playerId: playerId, move: move)]
        case let .firstMoveMade(playerMove):
            let moveMadeEvent = MoveMade(gameId: state.gameId, playerId: playerId, move: move)
            let gameResultEvent: DomainEvent = { () -> DomainEvent in
                if (playerMove.move == move) {
                    return GameTied(gameId: state.gameId)
                } else if playerMove.move.beats(move: move) {
                    return GameWon(gameId: state.gameId, winnerId: playerMove.playerId)
                } else {
                    return GameWon(gameId: state.gameId, winnerId: playerId)
                }
            }()
            return [moveMadeEvent, gameResultEvent]
        default:
            return []
        }
    }
    
    static func handle(state: GameState, cmd: Command) -> [DomainEvent] {
        switch cmd {
        case let .createGame(gameId, createdBy):
            return createGame(state: state, gameId: gameId, createdBy: createdBy)
        case let .play(_, playerId, move):
            return play(state: state, playerId: playerId, move: move)
        }
    }
}
