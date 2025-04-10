#!/usr/bin/env bash
#  c4cli.sh - A simple chess game interface in bash
#
# created: 2025-04-03
# author: Albert R. Carnier Guedes <albert@teko.net.br>
#
# MIT License <https://opensource.org/licenses/MIT>
# 
# Copyright (c) 2025 Albert R. Carnier Guedes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#   
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
set -e 

VERSION="0.1.0"

#
# Pieces Styles
#

# Letter style
PIECES_LETTERS=("." 
    "K" "Q" "R" "B" "N" "P" 
    "k" "q" "r" "b" "n" "p")
PIECES_LETTERS_COORDINATES_X=("a" "b" "c" "d" "e" "f" "g" "h")
PIECES_LETTERS_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# UTF-8 style
PIECES_UTF8=("\u00B7" 
    "\u265A" "\u265B" "\u265C" "\u265D" "\u265E" "\u265F" 
    "\u2654" "\u2655" "\u2656" "\u2657" "\u2658" "\u2659"
)
PIECES_UTF8_COORDINATES_X=("a" "b" "c" "d" "e" "f" "g" "h")
PIECES_UTF8_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# Set style
if [[ "$(tty)" =~ "tty" ]]; then
    # If console tty, uses letters 
    PIECES=("${PIECES_LETTERS[@]}")
    PIECES_COORDINATES_X=("${PIECES_LETTERS_COORDINATES_X[@]}")
    PIECES_COORDINATES_Y=("${PIECES_LETTERS_COORDINATES_Y[@]}")
else
    # If not console, uses UTF-8
    PIECES=("${PIECES_UTF8[@]}")
    PIECES_COORDINATES_X=("${PIECES_UTF8_COORDINATES_X[@]}")
    PIECES_COORDINATES_Y=("${PIECES_UTF8_COORDINATES_Y[@]}")
fi

#
# Board State
#
INITIAL_BOARD=(
     9 11 10  8  7 10 11  9
    12 12 12 12 12 12 12 12
     0  0  0  0  0  0  0  0
     0  0  0  0  0  0  0  0
     0  0  0  0  0  0  0  0
     0  0  0  0  0  0  0  0
     6  6  6  6  6  6  6  6
     3  5  4  2  1  4  5  3
)
BOARD=("${INITIAL_BOARD[@]}")

#
# Player State
#
PLAYER_IS_WHITE=1
PLAYER_TURN=1

#
# Message
#
MESSAGE=""

#
# This function is the "brain" of the script. It evaluates the move. 
# It is generic enough to be easily adapted to a chess engine to validate moves 
# or to use your custom rules. For now it has basic rules.
#
function evaluates_move(){
    local -i from_square=$1
    local -i from_piece_id=$2
    local -i to_square=$3
    local -i to_piece_id=$4

    if [[ $from_square -lt 0 || $from_square -gt 63 ]]; then
        echo "Error: from_square is out of range in evaluates_move()" >&2
        return 1
    fi

    if [[ $to_square -lt 0 || $to_square -gt 63 ]]; then
        echo "Error: to_square is out of range in evaluates_move()" >&2
        return 1
    fi

    if [[ $from_piece_id -lt 0 || $from_piece_id -gt 12 ]]; then
        echo "Error: from_piece_id is out of range in evaluates_move()" >&2
        return 1
    fi

    if [[ $to_piece_id -lt 0 || $to_piece_id -gt 12 ]]; then
        echo "Error: to_piece_id is out of range in evaluates_move()" >&2
        return 1
    fi

    # 1st rule: Check if the moved piece is of the player's turn.
    if [[ $from_piece_id -eq 0 ]]; then
        MESSAGE="There is no piece to move in that square."
        return 1
    elif [[ $PLAYER_TURN -eq 1 ]] && [[ $from_piece_id -gt 6 ]]; then
        MESSAGE="You cant move black piece."
        return 1
    elif [[ $PLAYER_TURN -eq 0 ]] && [[ $from_piece_id -lt 7 ]]; then
        MESSAGE="You cant move white piece."
        return 1
    fi

    # 2nd rule: Check if the piece being captured belongs to the opponent
    if [[ $to_piece_id -gt 0 ]]; then
       if [[ $PLAYER_TURN -eq 1 ]] && [[ $to_piece_id -le 6 ]]; then
            MESSAGE="You cant take white piece."
            return 1
        elif [[ $PLAYER_TURN -eq 0 ]] && [[ $to_piece_id -gt 6 ]]; then
            MESSAGE="You cant take black piece."
            return 1
        fi
    fi

    return 0
}

function coordenates_to_square(){
    local ascii_x
    local x y
    local square

    if [[ -z "${1:0:1}" ]]; then
        echo "Error: coordenates_to_square() - 1st parameter is null" >&2
        return 1
    fi

    if [[ -z "${1:1:1}" ]]; then
        echo "Error: coordenates_to_square() - 2nd parameter is null" >&2
        return 1
    fi

    ascii_x="$(printf "%d" "'${1:0:1}")"
    if [[ $ascii_x -lt 97 || $ascii_x -gt 104 ]]; then
        echo "Error: coordenates_to_square() - 1st parameter is out of range" >&2
        return 1
    fi

    x=$(( $ascii_x - 97 )) # 97 = 'a' ascii

    y=${1:1:1}
    if [[ $y -lt 1 || $y -gt 8 ]]; then
        echo "Error: coordenates_to_square() - 2nd parameter is out of range" >&2
        return 1
    fi

    square=$(( (8-$y) * 8 + $x ))
    printf "%d" $square

    return 0
}

function move_piece(){
    local move_string="$1"
    if [[ -z "$move_string" || ${#move_string} -ne 4 ]]; then
        echo "Error: Invalid move string" >&2
        return 1
    fi

    local -i from_square=$(coordenates_to_square "${move_string:0:2}")
    local -i to_square=$(coordenates_to_square "${move_string:2:2}")

    if [[ $from_square -lt 0 || $to_square -lt 0 ]]; then
        echo "Error: Invalid square coordinates" >&2
        return 1
    fi

    local -i from_piece_id=${BOARD[$from_square]}
    local -i to_piece_id=${BOARD[$to_square]}

    if ! evaluates_move $from_square $from_piece_id $to_square $to_piece_id; then
        return 1
    fi

    BOARD[$to_square]=$from_piece_id
    BOARD[$from_square]=0

    [[ $PLAYER_TURN -eq 1 ]] && PLAYER_TURN=0 || PLAYER_TURN=1

    return 0
}

function show_board(){
    local piece_id
    local x y
    local square

    if [[ ${#PIECES_COORDINATES_Y[@]} -ne 8 ]]; then
        echo "Error: PIECES_COORDINATES_Y has wrong size" >&2
        return 1
    fi

    if [[ ${#PIECES_COORDINATES_X[@]} -ne 8 ]]; then
        echo "Error: PIECES_COORDINATES_X has wrong size" >&2
        return 1
    fi

    if [[ ${#BOARD[@]} -ne 64 ]]; then
        echo "Error: BOARD has wrong size" >&2
        return 1
    fi

    if [[ ${#PIECES[@]} -ne 13 ]]; then
        echo "Error: PIECES has wrong size" >&2
        return 1
    fi

    for (( y = 7; y >= 0; y-- )); do
        # Print row labels on left side of the board
        if [[ -z "${PIECES_COORDINATES_Y[$y]}" ]]; then
            echo "Error: PIECES_COORDINATES_Y[$y] is null" >&2
            return 1
        fi

        printf "%s " "${PIECES_COORDINATES_Y[$y]}"

        # Print pieces
        for (( x = 0; x < 8; x++ )); do
            square="$(( (7-$y) * 8 + $x ))" 
            piece_id="${BOARD[$square]}"
            if [[ -z "${PIECES[$piece_id]}" ]]; then
                echo "Error: PIECES[$piece_id] is null" >&2
                return 1
            fi

            printf "${PIECES[$piece_id]} " 
        done    

        printf "\n" 
    done

    # Print column labels on foot
    printf "  "
    for (( x = 0; x < 8; x++ )); do 
        if [[ -z "${PIECES_COORDINATES_X[$x]}" ]]; then
            echo "Error: PIECES_COORDINATES_X[$x] is null" >&2
            return 1
        fi

        printf "${PIECES_COORDINATES_X[$x]} "
    done

    printf "\n\n"

    return 0
}

function continue_command(){
    if ! read -p "Press enter to continue..."; then
        echo "Error: unable to read user input" >&2
        return 1
    fi

    return 0
}

function help_command(){
    cat <<HELP

Commands:
    xyXY     - move piece from xy to XY (ex: e2e4, from e2 to e4)
    q | quit - quit the game    
    h | help - show this help

HELP

    if ! continue_command; then
        echo "Error: help_command() - unable to show help" >&2
        return 1
    fi

    return 0
}

function options(){
    local cmd="$1"
    local arg="$2"

    if [[ -z "$cmd" ]]; then
        echo "Error: cmd is null" >&2
        return 1
    fi

    case $cmd in
        q|quit) exit 0;;
        [a-h][1-8][a-h][1-8]) move_piece "$cmd";;
        h|help) help_command;;
        *) MESSAGE="Invalid command.";;
    esac

    return 0
}

function show_prompt() {
    local cmd arg
    local color who

    if [[ -z "$PLAYER_TURN" ]]; then
        echo "Error: PLAYER_TURN is not set" >&2
        return 1
    fi

    if [[ -z "$PLAYER_IS_WHITE" ]]; then
        echo "Error: PLAYER_IS_WHITE is not set" >&2
        return 1
    fi

    [[ $PLAYER_TURN -eq 1 ]] && who="you" || who="opp"
    [[ $PLAYER_IS_WHITE -eq $PLAYER_TURN ]] && color="white" || color="black"

    if ! read -r -p "(${who}) ${color}> " cmd arg; then
        echo "Error: unable to read input" >&2
        return 1
    fi

    if ! options "$cmd" "$arg"; then
        echo "Error: invalid command" >&2
        return 1
    fi

    return 0
}

function show_message(){
    if [[ "$MESSAGE" != "" ]]; then
        printf "\n%s " "$MESSAGE"
        MESSAGE=""

        if ! continue_command; then
            echo "Error: show_message() - unable to show prompt" >&2
            return 1
        fi
    fi

    return 0
}

function main(){
    while true; do
        clear
        show_board
        show_prompt
        show_message
    done

    return 0
}

main "$@" || {
    printf "An Error Ocurred.\n"
    exit 1
}
