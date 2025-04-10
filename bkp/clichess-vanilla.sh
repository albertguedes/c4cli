#!/usr/bin/env bash

set -e 

VERSION="0.1.0"

#
# Pieces Styles
#
# UTF-8 style
PIECES_UTF8=("\u00B7" 
    "\u265A" "\u265B" "\u265C" "\u265D" "\u265E" "\u265F" 
    "\u2654" "\u2655" "\u2656" "\u2657" "\u2658" "\u2659"
)
PIECES_UTF8_COORDINATES_X=("a" "b" "c" "d" "e" "f" "g" "h")
PIECES_UTF8_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# Set style
PIECES=("${PIECES_UTF8[@]}")
PIECES_COORDINATES_X=("${PIECES_UTF8_COORDINATES_X[@]}")
PIECES_COORDINATES_Y=("${PIECES_UTF8_COORDINATES_Y[@]}")

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
# This function evaluates the move. 
# It is generic enough to be easily adapted to a chess engine to validate moves 
# correctly or use your custom rules. For now it has basic rules. 
#
function evaluates_move(){
    local -i from_square=$1
    local -i from_piece_id=$2
    local -i to_square=$3
    local -i to_piece_id=$4

    # Check if the moved piece is the player turn.
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

    # Check if the piece taken is of the opposite color
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
    local ascii_x="$(printf "%d" "'${1:0:1}")"
    local x=$(( $ascii_x - 97 )) # 97 = 'a' ascii
    local y=${1:1:1}
    local square=$(( (8-$y) * 8 + $x ))
    printf "%d" $square
}

function move_piece(){
    local move_string="$1"
    local -i from_square=$(coordenates_to_square "${move_string:0:2}")
    local -i from_piece_id=${BOARD[$from_square]}    
    local -i to_square=$(coordenates_to_square "${move_string:2:2}")
    local -i to_piece_id=${BOARD[$to_square]}

    ! evaluates_move $from_square $from_piece_id $to_square $to_piece_id && return 1

    BOARD[$to_square]=$from_piece_id
    BOARD[$from_square]=0

    [[ $PLAYER_TURN -eq 1 ]] && PLAYER_TURN=0 || PLAYER_TURN=1

    return 0
}

function show_board(){
    local x y
    local piece_id
    local square

    for (( y = 7; y >= 0; y-- )); do
        # Print row labels on left side of the board
        printf "%s " "${PIECES_COORDINATES_Y[$y]}"

        # Print pieces
        for (( x = 0; x < 8; x++ )); do
            square="$(( (7-$y) * 8 + $x ))" 
            piece_id="${BOARD[$square]}"
            printf "${PIECES[$piece_id]} " 
        done    

        printf "\n" 
    done

    # Print column labels on foot
    printf "  "
    for (( x = 0; x < 8; x++ )); do 
        printf "${PIECES_COORDINATES_X[$x]} "
    done

    printf "\n\n"
}

function show_prompt() {
    local cmd arg
    local color who             

    [[ $PLAYER_TURN -eq 1 ]] && who="you" || who="opp"
    [[ $PLAYER_IS_WHITE -eq $PLAYER_TURN ]] && color="white" || color="black"

    read -r -p "(${who}) ${color}> " cmd arg

    case $cmd in
        q|quit) exit 0;;
        [a-h][1-8][a-h][1-8]) move_piece "$cmd";;
        *) MESSAGE="Invalid command.";;
    esac
}

function show_message(){
    if [[ "$MESSAGE" != "" ]]; then
        printf "\n%s " "$MESSAGE"
        MESSAGE=""
        read -p "Press enter to continue..." -r
    fi
}

function main(){
    while true; do
        clear
        show_board
        show_prompt
        show_message
    done
}

main "$@" || {
    printf "An Error Ocurred.\n"
    exit 1
}
