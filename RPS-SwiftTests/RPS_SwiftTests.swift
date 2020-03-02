//
//  RPS_SwiftTests.swift
//  RPS-SwiftTests
//
//  Created by Carl-Johan Heinze on 2020-03-02.
//  Copyright © 2020 Carl-Johan Heinze. All rights reserved.
//

import XCTest
@testable import RPS_Swift

class RPS_SwiftTests: XCTestCase {
    
    func test_returns_game_created_event_with_supplied_game_id_and_creator_when_creating_new_game() {
        // Given
        let gameId = GameId()
        let playerId = PlayerId()
        let state = GameState(gameId: gameId, gameProgress: .uninitialized)
        
        // When
        let events = Game.handle(state: state, cmd: .createGame(gameId, playerId))
        
        XCTAssert(events.count == 1)
        XCTAssert(events.contains(where: { (event) -> Bool in
            guard let gameCreated = event as? GameCreated else {
                return false
            }
            return gameCreated == GameCreated(gameId: gameId, createdBy: playerId)
        }))
    }
    
    func test_returns_move_made_event_with_supplied_game_id_player_id_and_move_player_is_making_the_first_move_of_the_game() {
        // Given
        let gameId = GameId()
        let playerId = PlayerId()
        let previousEvents = [GameCreated(gameId: gameId, createdBy: playerId)]
        
        let state = RecreateGameState.recreateGameStateFrom(events: previousEvents)
        let cmd: Command = .play(gameId, playerId, .rock)
        
        // When
        let events = Game.handle(state: state, cmd: cmd)
        
        XCTAssert(events.count == 1)
        XCTAssert(events.contains(where: { (event) -> Bool in
            guard let event = event as? MoveMade else {
                return false
            }
            return event == MoveMade(gameId: gameId, playerId: playerId, move: .rock)
        }))
    }
    
    func test_returns_move_made_and_game_won_events_when_second_player_beats_first_player() {
        // Given
        let gameId = GameId()
        let firstPlayerId = PlayerId()
        let secondPlayerId = PlayerId()
        let previousEvents: [DomainEvent] = [GameCreated(gameId: gameId, createdBy: firstPlayerId),
                                             MoveMade(gameId: gameId, playerId: firstPlayerId, move: .rock)]
        
        let state = RecreateGameState.recreateGameStateFrom(events: previousEvents)
        let cmd: Command = .play(gameId, secondPlayerId, .paper)
        
        // When
        let events = Game.handle(state: state, cmd: cmd)
        
        XCTAssert(events.count == 2)
        XCTAssert(events.contains(where: { (event) -> Bool in
            if let event = event as? MoveMade {
                return event == MoveMade(gameId: gameId, playerId: secondPlayerId, move: .paper)
            } else if let event = event as? GameWon {
                return event == GameWon(gameId: gameId, winnerId: secondPlayerId)
            }
            return false
        }))
    }
    
    func test_returns_move_made_and_game_tied_events_when_second_player_makes_same_move_as_first_player() {
        // Given
        let gameId = GameId()
        let firstPlayerId = PlayerId()
        let secondPlayerId = PlayerId()
        let previousEvents: [DomainEvent] = [GameCreated(gameId: gameId, createdBy: firstPlayerId),
                                             MoveMade(gameId: gameId, playerId: firstPlayerId, move: .scissors)]
        
        let state = RecreateGameState.recreateGameStateFrom(events: previousEvents)
        let cmd: Command = .play(gameId, secondPlayerId, .scissors)
        
        // When
        let events = Game.handle(state: state, cmd: cmd)
        
        XCTAssert(events.count == 2)
        XCTAssert(events.contains(where: { (event) -> Bool in
            if let event = event as? MoveMade {
                return event == MoveMade(gameId: gameId, playerId: secondPlayerId, move: .scissors)
            } else if let event = event as? GameTied {
                return event == GameTied(gameId: gameId)
            }
            return false
        }))
    }
}
