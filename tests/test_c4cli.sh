#!/usr/bin/env bash

# Test script for src/clichess.sh

# Include clichess.sh script
source ../src/clichess.sh

function test_evaluates_move() {
    # Test evaluates_move function
    local result

    # Test moving a white piece out of turn
    result=$(evaluates_move 0 1 1 0)
    if [[ $? -eq 0 ]]; then
        echo "Test evaluates_move: Moving a white piece out of turn should return 1. Got: $result"
        return 1
    fi

    # Test moving a black piece out of turn
    result=$(evaluates_move 0 7 1 0)
    if [[ $? -eq 0 ]]; then
        echo "Test evaluates_move: Moving a black piece out of turn should return 1. Got: $result"
        return 1
    fi

    # Test moving a piece to a square occupied by a piece of the same color
    result=$(evaluates_move 0 1 1 1)
    if [[ $? -eq 0 ]]; then
        echo "Test evaluates_move: Moving a piece to a square occupied by a piece of the same color should return 1. Got: $result"
        return 1
    fi

    # Test moving a piece to a square occupied by a piece of the opposite color
    result=$(evaluates_move 0 1 1 7)
    if [[ $? -ne 0 ]]; then
        echo "Test evaluates_move: Moving a piece to a square occupied by a piece of the opposite color should return 0. Got: $result"
        return 1
    fi
}

function test_coordenates_to_square(){
    # Test coordenates_to_square function
    local result

    # Test converting a coordinate to a square value
    result=$(coordenates_to_square "a1")
    if [[ $result -ne 0 ]]; then
        echo "Test coordenates_to_square: Converting a coordinate to a square value should return 0. Got: $result"
        return 1
    fi

    # Test converting an invalid coordinate to a square value
    result=$(coordenates_to_square "z1")
    if [[ $result -ne 1 ]]; then
        echo "Test coordenates_to_square: Converting an invalid coordinate to a square value should return 1. Got: $result"
        return 1
    fi
}

function test_move_piece(){
    # Test move_piece function
    local result

    # Test moving a piece to a valid position
    result=$(move_piece "a1a2")
    if [[ $? -ne 0 ]]; then
        echo "Test move_piece: Moving a piece to a valid position should return 0. Got: $result"
        return 1
    fi

    # Test moving a piece to an invalid position
    result=$(move_piece "a1z2")
    if [[ $? -ne 1 ]]; then
        echo "Test move_piece: Moving a piece to an invalid position should return 1. Got: $result"
        return 1
    fi
}

function test_show_board(){
    # Test show_board function
    local result

    # Test showing the board
    result=$(show_board)
    if [[ $? -ne 0 ]]; then
        echo "Test show_board: Showing the board should return 0. Got: $result"
        return 1
    fi
}

function test_continue_command(){
    # Test continue_command function
    local result

    # Test continuing the game
    result=$(continue_command)
    if [[ $? -ne 0 ]]; then
        echo "Test continue_command: Continuing the game should return 0. Got: $result"
        return 1
    fi
}

function test_help_command(){
    # Test help_command function
    local result

    # Test showing help
    result=$(help_command)
    if [[ $? -ne 0 ]]; then
        echo "Test help_command: Showing help should return 0. Got: $result"
        return 1
    fi
}

function test_options(){
    # Test options function
    local result

    # Test invalid command
    result=$(options "invalid")
    if [[ $? -ne 1 ]]; then
        echo "Test options: Invalid command should return 1. Got: $result"
        return 1
    fi
}

function test_show_prompt(){
    # Test show_prompt function
    local result

    # Test showing prompt
    result=$(show_prompt)
    if [[ $? -ne 0 ]]; then
        echo "Test show_prompt: Showing prompt should return 0. Got: $result"
        return 1
    fi
}

function test_show_message(){
    # Test show_message function
    local result

    # Test showing the message
    MESSAGE="Test message"
    result=$(show_message)
    if [[ $? -ne 0 ]]; then
        echo "Test show_message: Showing the message should return 0. Got: $result"
        return 1
    fi
}

function test_main(){
    # Test main function
    local result

    # Test running the game
    result=$(main)
    if [[ $? -ne 0 ]]; then
        echo "Test main: Running the game should return 0. Got: $result"
        return 1
    fi
}

function test_integration(){
    # Test integration function
    local result

    # Test running the game
    MESSAGE="Test message"
    result=$(main "show_board" "move_piece" "a1" "a2")
    if [[ $? -ne 0 ]]; then
        echo "Test integration: Running the game should return 0. Got: $result"
        return 1
    fi
}

# Run tests
test_evaluates_move
test_coordenates_to_square
test_move_piece
test_show_board
test_continue_command
test_help_command
test_options
test_show_prompt
test_show_message
test_main
test_integration

echo "All tests completed."

