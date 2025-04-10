#!/usr/bin/env bash

set -e 

VERSION="0.1.2"

#
# Engine to verify legal moves
# 
engine_file="$PWD/engines/clichess.engine"
[[ -f "$engine_file" ]] || { echo "Error: Engine not found"; exit 1; }    
. "$engine_file"

#
# Board
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
BOARD_FLIPPED=0
BOARD_COORDINATES=0

#
# Pieces Styles
#

# Letter style
PIECES_LETTERS=("." "K" "Q" "R" "B" "N" "P" "k" "q" "r" "b" "n" "p")
PIECES_LETTERS_COORDINATES_X=("a" "b" "c" "d" "e" "f" "g" "h")
PIECES_LETTERS_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# Raw style
PIECES_RAW=(" 0" " 1" " 2" " 3" " 4" " 5" " 6" " 7" " 8" " 9" "10" "11" "12")
PIECES_RAW_COORDINATES_X=(" a" " b" " c" " d" " e" " f" " g" " h")
PIECES_RAW_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# UTF-8 style
PIECES_UTF8=("\u00B7" "\u265A" "\u265B" "\u265C" "\u265D" "\u265E" "\u265F" "\u2654" "\u2655" "\u2656" "\u2657" "\u2658" "\u2659")
PIECES_UTF8_COORDINATES_X=("a" "b" "c" "d" "e" "f" "g" "h")
PIECES_UTF8_COORDINATES_Y=("1" "2" "3" "4" "5" "6" "7" "8")

# Register styles
PIECES_STYLES=("letters" "raw" "utf8")

# Current Style
PIECES_STYLE_CURRENT=0

PIECES=("${PIECES_LETTERS[@]}")
PIECES_COORDINATES_X=("${PIECES_LETTERS_COORDINATES_X[@]}")
PIECES_COORDINATES_Y=("${PIECES_LETTERS_COORDINATES_Y[@]}")

#
# Player
#
PLAYER_IS_WHITE=1
PLAYER_TURN=1

#
# Message box
#
MESSAGE="Bem Vindo Ao Clichess $VERSION"

function show_message() {
    if [[ -z "$MESSAGE" ]]; then
        printf "\n%s\n" $MESSAGE
        MESSAGE=''
        continue_command
    fi
}

#
# Player functions
#
function toggle_player() {
    [[ $PLAYER_IS_WHITE -eq 1 ]] && PLAYER_IS_WHITE=0 || PLAYER_IS_WHITE=1
}

function toggle_turn() {
    [[ $PLAYER_TURN -eq 1 ]] && PLAYER_TURN=0 || PLAYER_TURN=1
}

#
# Board functions
#
function board_to_fen() {
    local  fen=''
    local -i empty_count=0

    # Check if BOARD is not defined
    if [[ -z "${BOARD[*]}" ]]; then
        echo "Error: BOARD is not defined." >&2
        return 1
    fi

    for ((i = 0; i < 64; i++)); do
        if [[ "${BOARD[i]}" -eq 0 ]]; then
            ((empty_count++))
        else
            ((empty_count > 0)) && fen+="$empty_count"
            fen+="${PIECES_LETTERS[${BOARD[$i]}]}"
            empty_count=0
        fi

        if (( (i + 1) % 8 == 0 )); then
            ((empty_count > 0)) && fen+="$empty_count"
            fen+="/"
            empty_count=0
        fi
    done

    fen="${fen%/}"

    [ $PLAYER_TURN -eq $PLAYER_IS_WHITE ] && fen+=' w' || fen+=' b'

    printf "%s" "$fen" && return 0 || return 1 
}

function expand_fen() {
    local fen="$1"
    local expanded_fen=''

    # Check if fen is not defined
    if [[ -z "$fen" ]]; then
        echo "Error: FEN string is null or empty" >&2
        return 1
    fi

    # Check if fen is not a string
    if [[ ! "$fen" =~ ^[[:print:]]+$ ]]; then
        echo "Error: FEN string is not a string" >&2
        return 1
    fi

    for ((i = 0; i < 64; i++)); do
        if [[ "${fen:i:1}" =~ [0-9] ]]; then
            for ((j = 0; j < "${fen:i:1}"; j++)); do
                expanded_fen+="."
            done
        else
            expanded_fen+="${fen:i:1}"
        fi
    done

    printf "%s" "$expanded_fen"
}

function fen_to_board() {
    local fen="$1" 

    # Check for null or empty input
    if [[ -z "$fen" ]]; then
        echo "Error: FEN string is null or empty" >&2
        return 1
    fi

    local turn="${fen##* }" 

    PLAYER_TURN=1

    case "$turn" in
        "w")
            PLAYER_IS_WHITE=1
            BOARD_FLIPPED=0
            break;;

        "b")
            PLAYER_IS_WHITE=0
            BOARD_FLIPPED=1 
            break;;

        *)
            echo "Error: FEN turn is invalid" >&2
            return 1
    esac

    local positions="${fen%% *}"

    # Validate the FEN
    if [[ ! "$positions" =~ ^([rnbqkpRNBQKP1-8]+\/){7}[rnbqkpRNBQKP1-8]+$ ]]; then
        echo "Error: invalid FEN" >&2
        return 1
    fi

    # Expand the FEN to a 64 character string
    local expanded_positions="$(expand_fen "$positions")"

    # Split the FEN on ranks and fill the board
    IFS='/' read -ra rank_strings <<< "$expanded_positions"
    if [[ ${#rank_strings[@]} != 8 ]]; then
        echo "Error: FEN contains unexpected number of ranks" >&2
        return 1
    fi

    local piece_id=0
    for rank_string in "${rank_strings[@]}"; do
        for ((j = 0; j < 8; j++)); do

            if [[ -z "${rank_string:j:1}" ]]; then
                echo "Error: FEN contains unexpected end of rank" >&2
                return 1
            fi

            case "${rank_string:j:1}" in
                .) BOARD[$piece_id]=0 ;;
                K) BOARD[$piece_id]=1 ;;
                Q) BOARD[$piece_id]=2 ;;
                R) BOARD[$piece_id]=3 ;;
                B) BOARD[$piece_id]=4 ;;
                N) BOARD[$piece_id]=5 ;;
                P) BOARD[$piece_id]=6 ;;
                k) BOARD[$piece_id]=7 ;;
                q) BOARD[$piece_id]=8 ;;
                r) BOARD[$piece_id]=9 ;;
                b) BOARD[$piece_id]=10 ;;
                n) BOARD[$piece_id]=11 ;;
                p) BOARD[$piece_id]=12 ;;
                *) echo "Error: unexpected character" >&2; return 1 ;;
            esac

            ((piece_id++))
        done
    done
}

function set_pieces_style(){
    if [ -z "$1" ]; then
        printf "Available styles:\n"
        for style_id in "${!PIECES_STYLES[@]}"; do
            if [[ $style_id == $PIECES_STYLE_CURRENT ]]; then
                printf "\n- %s (current)" "${PIECES_STYLES[$style_id]}"
            else
                printf "\n- %s" "${PIECES_STYLES[$style_id]}"
            fi
        done
        printf "\n\n"
    else
        if [[ -z "${PIECES_STYLES[$1]}" ]]; then
            echo "Error: invalid style" >&2
            return 1
        fi
 
        for style_id in "${!PIECES_STYLES[@]}"; do
            if [[ "${PIECES_STYLES[$style_id]}" == "$1" ]]; then
                PIECES_STYLE_CURRENT=$style_id
                break
            fi
        done

        case $style_id in
            0)
                PIECES=("${PIECES_LETTERS[@]}")
                PIECES_COORDINATES_X=("${PIECES_LETTERS_COORDINATES_X[@]}")
                PIECES_COORDINATES_Y=("${PIECES_LETTERS_COORDINATES_Y[@]}")
                ;;
            1)
                PIECES=("${PIECES_RAW[@]}")
                PIECES_COORDINATES_X=("${PIECES_RAW_COORDINATES_X[@]}")
                PIECES_COORDINATES_Y=("${PIECES_RAW_COORDINATES_Y[@]}")
                ;;
            2)
                PIECES=("${PIECES_UTF8[@]}")
                PIECES_COORDINATES_X=("${PIECES_UTF8_COORDINATES_X[@]}")
                PIECES_COORDINATES_Y=("${PIECES_UTF8_COORDINATES_Y[@]}")
                ;;
            *)
                echo "Error: invalid style" >&2
                return 1
                ;;
        esac
    fi
}

function print_board() {
    local -i piece_id 
    local -a row_labels col_labels

    if [[ -z ${BOARD[@]} ]]; then
        echo "Error: board is uninitialized"
        return 1
    fi

    if [[ $BOARD_FLIPPED -eq 1 ]]; then
        for ((i = 0; i < 8; i++)); do
            col_labels[$i]="${PIECES_COORDINATES_X[7 - $i]}"
            row_labels[$i]="${PIECES_COORDINATES_Y[7 - $i]}"
        done
    else
        col_labels=("${PIECES_COORDINATES_X[@]}")        
        row_labels=("${PIECES_COORDINATES_Y[@]}")
    fi

    for ((i = 0; i < 64; i++)); do
        if [[ $BOARD_COORDINATES -eq 1 ]] && [[ $((i % 8)) -eq 0 ]]; then
            printf "%b " "${row_labels[7-i/8]}"
        fi

        if [[ $BOARD_FLIPPED -eq 1 ]]; then
            piece_id="${BOARD[63 - i]}"
        else
            piece_id="${BOARD[i]}"
        fi

        if [[ -z "${PIECES[$piece_id]}" ]]; then
            echo "Error: piece is uninitialized"
            return 1
        fi

        printf "%b " "${PIECES[$piece_id]}"

        # Newline after each row
        [[ $(( (i + 1) % 8 )) -eq 0 ]] && echo
    done

    # Print column labels
    if [[ $BOARD_COORDINATES -eq 1 ]]; then
        printf "  "
        for label in "${col_labels[@]}"; do
            printf "%b " "$label"
        done
        printf "\n"
    fi

    printf "\n"
}

function reset_board() {
    if [[ -z "${INITIAL_BOARD[@]}" ]]; then 
        echo "Error: Initial board state is uninitialized"; 
        return 1;
    fi

    BOARD=("${INITIAL_BOARD[@]}") # Set the board to the initial state
    if [[ $PLAYER_IS_WHITE -eq 1 ]]; then
        PLAYER_TURN=1
        BOARD_FLIPPED=0
    else
        PLAYER_TURN=0   
        BOARD_FLIPPED=1
    fi
}

function move_piece_board() {
    local  move="$1"

    local from_x="${move:0:1}"
    local from_y="${move:1:1}"
    local to_x="${move:2:1}"
    local to_y="${move:3:1}"

    local from_x_idx=$(( $(printf "%d" "'$from_x") - 97 ))
    local to_x_idx=$(( $(printf "%d" "'$to_x") - 97 ))

    local from_y_idx=$((8 - from_y))
    local to_y_idx=$((8 - to_y))

    local from_idx=$((from_y_idx * 8 + from_x_idx))
    local to_idx=$((to_y_idx * 8 + to_x_idx))

    # Get current state
    local current_fen="$(board_to_fen)"
    local to_piece=${BOARD[$to_idx]}
    local from_piece=${BOARD[$from_idx]}

    # Move the piece
    BOARD[$to_idx]=$from_piece
    BOARD[$from_idx]=0
    toggle_turn

    # Get new state
    local new_fen="$(board_to_fen)"

    if ! is_valid_move "$current_fen" "$new_fen"; then
        toggle_turn 
        BOARD[$to_idx]=$to_piece
        BOARD[$from_idx]=$from_piece
        MESSAGE="\n%s\n\n" "Invalid move"
    else
        return 0
    fi
}

function toggle_flipped_board() {
    [[ $BOARD_FLIPPED == 1 ]] && BOARD_FLIPPED=0 || BOARD_FLIPPED=1
}

function toggle_coordinates_board() {
    [[ $BOARD_COORDINATES -eq 1 ]] && BOARD_COORDINATES=0 || BOARD_COORDINATES=1
}

#
# Others functions
#
function version(){
    printf "\n%s\n\n" "$VERSION"
}

#
# Prompt Commands
#
# Board Commands
function move_command() {
    move_piece_board "$cmd"
}

function fen_command() {
    local fen="$1"

    if [ -z "$fen" ]; then
        printf "\n%s\n\n" "$(board_to_fen)"
    else
        fen_to_board "$fen"
    fi

    continue_command
}

function toggle_flip_command() {
    toggle_flipped_board
}

function toggle_coordinates_command() {
    toggle_coordinates_board
}

function reset_command() {
    confirm_command "Reset the board?" && reset_board
}

function set_pieces_style_command() {
    if [[ -z "$1" ]]; then
        set_pieces_style
        continue_command
    else
        set_pieces_style "$1"
    fi         
}

# Player Commands
function toggle_player_command() {
    toggle_player
    toggle_turn
    toggle_flipped_board
}

# Session Commands

function exit_command() {
    printf "\nexiting ... bye!\n"
    exit 0
}

function confirm_command() {
    local  prompt="${1:-Are you sure?} (y/N): "
    read -r -p "$prompt" response
}

function continue_command(){
    local  message="$1"
    # If given message, print with continue message, so print only continue 
    # message and wait user type enter.
    read -r -p "${message}enter to continue ..."
}

function default_command(){
    local  response="$1"
    ![[ -z "$response" ]] && continue_command "invalid command!"
}

function help_command() {
    cat <<HELP

Available commands:
  h|help                      - Show this help message
  <move>                      - Make a move in xyXY format (e.g., e2e4)
  b|black                     - Set the player as black pieces
  c|coordinates               - Toggle the display of board coordinates  
  f|flip                      - Flip the board
  r|reset                     - Reset the board to the initial position
  s [<style>]|style [<style>] - Set the pieces style, show available styles without arg
  fen [<FEN>]                 - Without arg, display the current FEN, else,
                                load a position from a given FEN string. 
                                (ex: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w' )
  q|quit                      - Exit the game

HELP
    continue_command
}

function version_command() {
    version
    continue_command
}

#
# Interface:
#
#  - board
#  - command line
#  - messages
#
function show_board() {
    clear
    print_board
}

function show_prompt() {
    local color 
    local turn 
    local who             

    [[ $PLAYER_TURN -eq 1 ]] && who="you" || who="he"
    [[ $PLAYER_IS_WHITE -eq $PLAYER_TURN ]] && color="white" || color="black"

    read -r -p "(${who}) ${color}> " cmd arg
}

function play() {
    local fen="$1" 
    local cmd arg

    if [ -n "$fen" ]; then
        if ! fen_to_board "$fen"; then
            echo "Error: Invalid FEN string."
            return 1
        fi
    fi

    while true; do
        show_board
        show_prompt
        show_message
        case "$cmd" in
            h|help) help_command;;
            b|black) toggle_player_command;;
            c|coordinates) toggle_coordinates_command;;
            f|flip) toggle_flip_command;;
            r|reset) reset_command;;
            s|style) set_pieces_style_command "$arg";;
            fen) fen_command "$arg";;
            [a-h][1-8][a-h][1-8]) move_command "$cmd";;
            v|version) version_command;;
            q|quit) exit_command; echo "exiting ... bye!"; exit 0;;
            *) default_command;;
        esac
    done
}

#
# CLI Commands
#
function toggle_flip_cli() {
    toggle_flipped_board
}

function toggle_coordinates_cli() {
    toggle_coordinates_board
}

function set_pieces_style_cli() {
    set_pieces_style "$1"
    [[ -z "$1" ]] && exit 0
}

# Player CLI commands
function toggle_player_cli() {
    toggle_player
    toggle_flipped_board
    toggle_turn
}

# Session CLI commands
function help_cli() {
    cat <<HELP

clichess.sh ${VERSION} - a simple interface for command-line chess game.

Usage: $(basename "$0") [-h|--help] [-b|--black] [-c|--show-coordinates] [-f|--flip] [-s [<style>]|--style [<style>]] [<FEN>]

-h, --help                      Show this help message and exit
-b, --black                     Start the game as black pieces
-c, --coordinates               Show the board coordenates
-f, --flip                      Start with the board flipped
-s [<style>], --style [<style>] Set the pieces style (default, raw, utf8), show available styles without arg
[<FEN>]                         Start the game with a position from a FEN string.
                                (ex: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w' )
-v, --version                   Show the version number and exit

HELP
    exit 0
}

function version_cli() {
    version
    exit 0
}

function main(){
    local fen

    while (( $# > 0 )); do
        case "$1" in
            -h|--help) help_cli; break;;
            -v|--version) version_cli;;            
            -b|--black) toggle_player_cli;;
            -c|--coordinates) toggle_coordinates_cli;;
            -f|--flip) toggle_flip_cli;;
            -s|--style) 
                    set_pieces_style_cli "$2"
                    shift
                ;;
            *)
                if [[ "$1" == -* ]]; then
                    echo "Invalid command: $1"
                    exit 1
                else
                    fen="$1"
                fi
                break
                ;;
        esac
        shift
    done
    
    play "$fen"
}

main "$@" || {
    echo "An error occurred."
    exit 1
}
