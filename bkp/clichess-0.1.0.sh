#!/usr/bin/env bash
#
# clichess.sh - A simple interface for command-line chess game
#
# author: Albert R. Carnier Guedes <albert@teko.net.br>
# created: 2025-04-03
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

# Chess pieces styles.
LETTER_PIECES=("." "K" "Q" "R" "B" "N" "P" "k" "q" "r" "b" "n" "p")
UTF8_PIECES=("\u00B7" "\u265A" "\u265B" "\u265C" "\u265D" "\u265E" "\u265F" "\u2654" "\u2655" "\u2656" "\u2657" "\u2658" "\u2659")

# The board as an array.
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

# The board as an numerical array.
BOARD=("${INITIAL_BOARD[@]}")

# Indicates if the player is black ... pieces
PLAYER_IS_BLACK=false

# The current turn
IS_BLACK_TURN=false

# Indicates if the board should be flipped for black's perspective
BOARD_FLIPPED=false

# Toggle to show column letters on the board
SHOW_COORDINATES=false

# Toggle to use UTF-8 characters for chess pieces
USE_UTF8=false

# Toggle to use letters for chess pieces
USE_LETTERS=true

# Expand a FEN string to a 64 character string.
#
# Parameters:
#   $1 - A FEN string to expand.
#
# Returns:
#   A 64 character string where digits in the FEN have been replaced with
#   the corresponding number of '.'
expand_fen() {
    local fen="$1"
    local expanded_fen=""

    for ((i = 0; i < 64; i++)); do
        if [[ "${fen:i:1}" =~ [0-9] ]]; then
            for ((j = 0; j < "${fen:i:1}"; j++)); do
                expanded_fen+="."
            done
        else
            expanded_fen+="${fen:i:1}"
        fi
    done

    echo "$expanded_fen"
}

#
# Convert a FEN string to the internal board representation.
#
# This function takes a FEN (Forsyth-Edwards Notation) string as input,
# validates it, and updates the BOARD array to reflect the current
# positions of the chess pieces. The function only processes the piece
# positions part of the FEN string and ignores other details like castling
# rights or move counters.
#
# Parameters:
#   $1 - A FEN string representing the chess board state.
#
# Returns:
#   0 if the FEN string is valid and successfully processed.
#   1 if the FEN string is invalid or contains unexpected characters.
#
fen2board() {
    local fen="$1"
    local rank i=0

    # Remove extra information (get only the pieces position and player turn)
    fen="${fen%% *}"

    # Validate the FEN
    if [[ ! "$fen" =~ ^([rnbqkpRNBQKP1-8]+\/){7}[rnbqkpRNBQKP1-8]+$ ]]; then
        echo "Error: invalid FEN"
        return 1
    fi

    # Expand the FEN to a 64 character string
    fen=$(expand_fen "$fen")

    # Split the FEN on ranks and fill the BOARD
    IFS='/' read -ra ranks <<< "$fen"
    for rank in "${ranks[@]}"; do
        for ((j = 0; j < 8; j++)); do
            case "${rank:j:1}" in
                .) BOARD[i]=0 ;;
                K) BOARD[i]=1 ;;
                Q) BOARD[i]=2 ;;
                R) BOARD[i]=3 ;;
                B) BOARD[i]=4 ;;
                N) BOARD[i]=5 ;;
                P) BOARD[i]=6 ;;
                k) BOARD[i]=7 ;;
                q) BOARD[i]=8 ;;
                r) BOARD[i]=9 ;;
                b) BOARD[i]=10 ;;
                n) BOARD[i]=11 ;;
                p) BOARD[i]=12 ;;
                *) echo "Error: unexpected character"; return 1 ;;
            esac
            ((i++))
        done
    done

    IS_BLACK_TURN=$( [[ "${fen: -1}" == "b" ]] && echo true || echo false )
}

#
# Generate a FEN from current board state.
#
board2fen() {
    local fen=""
    local empty_count=0

    for ((i = 0; i < 64; i++)); do
        if [[ "${BOARD[i]}" -eq 0 ]]; then
            ((empty_count++))
        else
            ((empty_count > 0)) && fen+="$empty_count"
            fen+="${LETTER_PIECES[${BOARD[i]}]}"
            empty_count=0
        fi

        if (( (i + 1) % 8 == 0 )); then
            ((empty_count > 0)) && fen+="$empty_count"
            fen+="/"
            empty_count=0
        fi
    done

    fen="${fen%/}"
    fen+=" $( [[ "$TURN" == "white" ]] && echo "w" || echo "b" )"

    printf "%s" $fen
}

#
# Print the current board.
#
print_board() {
    local row_number column_labels

    for ((i = 0; i < 64; i++)); do

        if [[ $((i % 8)) -eq 0 ]]; then
            if [[ $SHOW_COORDINATES == true ]]; then
                row_number=$((8 - i/8))
                [[ $BOARD_FLIPPED == true ]] && row_number=$((9 - row_number))
                printf "%d " "$row_number"
            fi
        fi

        if [[ $BOARD_FLIPPED == true ]]; then
            piece="${BOARD[63-i]}"
        else
            piece="${BOARD[i]}"
        fi

        if [[ $USE_UTF8 == true ]]; then
            piece="${UTF8_PIECES[$piece]}"
            printf "%b " "$piece"
        elif [[ $USE_LETTERS == true ]]; then
            piece="${LETTER_PIECES[$piece]}"
            printf "%s " "$piece"
        else
            printf "%2d " "$piece"
        fi

        if [[ $(( (i + 1) % 8 )) -eq 0 ]]; then
            echo
        fi
    done

    if [[ $SHOW_COORDINATES == true ]]; then
        column_labels=("a" "b" "c" "d" "e" "f" "g" "h")
        if [[ $BOARD_FLIPPED == true ]]; then
            column_labels=("h" "g" "f" "e" "d" "c" "b" "a")
        fi

        printf "  "
        for ((i = 0; i < 8; i++)); do
            if [[ $USE_LETTERS == true || $USE_UTF8 == true ]]; then
                printf "%s " "${column_labels[i]}"
            else
                printf "%2s " "${column_labels[i]}"
            fi
        done
        printf "\n"
    fi
}

#
# Realize the move of piece on simple algebric format (ex: e2e4)
#
move_piece() {
    local move="$1"

    # Extract the coordenates (ex: e2e4 -> fromX=e, fromY=2, toX=e, toY=4)
    local fromX="${move:0:1}"
    local fromY="${move:1:1}"
    local toX="${move:2:1}"
    local toY="${move:3:1}"

    # Convert the a-h coluns to numerical coordenate 0-7
    local fromX_idx=$(( $(printf "%d" "'$fromX") - 97 )) # 'a' -> 0, 'b' -> 1, ..., 'h' -> 7
    local toX_idx=$(( $(printf "%d" "'$toX") - 97 ))

    # Convert the 1-8 rows to numerical coordenate 0-7
    local fromY_idx=$((8 - fromY))
    local toY_idx=$((8 - toY))

    # Compute the index on BOARD array.
    local from_idx=$((fromY_idx * 8 + fromX_idx))
    local to_idx=$((toY_idx * 8 + toX_idx))

    # Move the piece
    BOARD[to_idx]="${BOARD[from_idx]}"
    BOARD[from_idx]="0"

    # Alternate the turn.
    [[ $IS_BLACK_TURN == true ]] && TURN='white' || TURN='black'
}

#
# Reset the board to initial state.
#
# This function will reset the board to initial state (white moves first).
reset_board() {
    BOARD=(${INITIAL_BOARD[@]})
    IS_BLACK_TURN=false
}

#
# Initialize the board with a given FEN string or reset to the initial position.
#
# Parameters:
#   $1 - Optional, a FEN string to load into the board. If not provided,
#        the board is reset to the initial position.
#
# If a FEN string is provided, this function will attempt to load it into the
# board. If the FEN string is invalid, the function will exit with status 1.
# If no FEN string is provided, the function will reset the board to its initial
# position.
init_board() {
    [[ -n "$1" ]] && ! fen2board "$1" && exit 1 || reset_board
}

#
# Toggle the BOARD_FLIPPED flag. This flag controls the orientation of the
# board when printed. When true, the board is printed with the black pieces at
# the top (i.e., the board is flipped). When false, the board is printed with the
# white pieces at the top.
toggle_board_flipped() {
    [[ $BOARD_FLIPPED == true ]] && BOARD_FLIPPED=false || BOARD_FLIPPED=true
}

#
# Toggle the display of board coordinates.
#Start the game
# This function toggles the SHOW_COORDINATES flag, which controls whether
# the column letters and row numbers are displayed on the board. When true,
# the coordinates are shown; when false, they are hidden. After toggling,
# it calls the 'print_board' function to refresh the display.
#
toggle_coordinates() {
    [[ $SHOW_COORDINATES == true ]] && SHOW_COORDINATES=false || SHOW_COORDINATES=true
}

toggle_player() {
    [[ $PLAYER_IS_BLACK == true ]] && PLAYER_IS_BLACK=false || PLAYER_IS_BLACK=true
}

set_utf8() {
    USE_UTF8=true; USE_LETTERS=false;
}   

set_default() {
    USE_UTF8=false; USE_LETTERS=true;
}

set_raw() {
    USE_UTF8=false; USE_LETTERS=false;
}

#
# Prompt the user for confirmation.
#
# This function displays a confirmation prompt to the user and waits for a response.
# If the response is 'y' or 'Y', it returns 0 (indicating confirmation).
# For any other response, it returns 1 (indicating cancellation).
#
# Parameters:
#   $1 - Optional. The prompt message to display. Defaults to "Are you sure? (y/N): ".
#
confirm_command() {
    local prompt="${1:-Are you sure?} (y/N): "
    read -r -p "$prompt" response
    case "$response" in
        [Yy]) return 0;;  # Continue with the command
        *) return 1;;      # Cancel the command
    esac
}

#
# Wait for the user to press enter before continuing.
#
# This function displays a prompt ("enter to continue ...") and waits for the
# user to press enter before returning. This is useful for keeping the board
# visible for a few moments before auto-clearing.
continue_command(){
    read -r -p "\nenter to continue ..."
}

#
# Execute a move command.
#
# This function processes a move command in algebraic notation (e.g., e2e4)
# and calls the move_piece function to update the board state.
# The command should be stored in the global variable 'cmd'.
#
move_command(){
    move_piece "$cmd"
    [[ $IS_BLACK_TURN == true ]] && TURN='black' || TURN='white'
}

# Reset the board to the initial state, clearing all moves.
#
# This function displays a confirmation prompt to the user before resetting the
# board. If the user confirms, it calls the 'reset_board' function to reset the
# board state.
reset_command(){
    confirm_command "Reset the board?" && reset_board
}

#
# Load a FEN string.
#
# This function takes one argument, a FEN string.
# If no argument is passed, it displays the current FEN string.
# If an argument is passed, it prompts the user to confirm the change, and if
# the user confirms, it attempts to load the FEN string. If the FEN string is
# invalid, it displays an error message.
fen_command() {
    if [[ -z "$1" ]]; then
        # If no argument is passed, show the current FEN
        board2fen
        echo ""
    else
        # If an argument is passed, try to load the FEN
        if confirm_command "Load this FEN?"; then
            if fen2board "$1"; then
                echo "FEN loaded successfully."
            else
                echo "Invalid FEN format."
            fi
        fi
    fi
    continue_command
}

#
# Default command.
#
# This function is called when no other command is matched. If the user entered
# some text, it displays an error message and waits for the user to press enter
# before continuing. If the user didn't enter any text, it does nothing.
default_command(){
    ![[ -z "$response" ]] && {
        echo "invalid command!"
        continue_command
    }
}

# Exit the program.
#
# This function displays a goodbye message and exits the program with success (0).
exit_command(){
    printf "\nexiting ... bye!\n"
    exit 0
}

#
# Show the current board.
#
# This function clears the screen and prints the current state of the board.
show_board(){
    clear
    print_board
    printf "\n"
}

#
# prompt - Prompt the user for a command.
#
# This function displays a prompt (e.g., "white> " or "black> ") and waits for
# the user to enter a command. It stores the user's input in the global
# variables 'cmd' and 'arg'.
show_prompt(){
    read -r -p "${TURN}> " cmd arg
}

# 
# Show this help message and exit.
#
# This function displays the help message and waits for the user to press
# enter before returning.
help_command() {
    cat <<HELP
Available commands:
  h|help        - Show this help message
  <move>        - Make a move in xyXY format (e.g., e2e4)
  b|black       - Set the player as black pieces
  c|coordinates - Toggle the display of board coordinates  
  f|flip        - Flip the board
  r|reset       - Reset the board to the initial position
  default       - Show the chess pieces in default chars (letters)
  raw           - Show the chess pieces in raw format (numbers)
  utf8          - Show the chess pieces in UTF-8 icons
  fen [<FEN>]   - Without arg, display the current FEN, else,
                  load a position from a given FEN string
  q|quit        - Exit the game
HELP
    continue_command
}

#
# play_chess - Play a chess game.
#
# Parameters:
#   FEN - Optional, a FEN (Forsyth-Edwards Notation) to start the game with.
#
# This function will loop until the user types "exit" or "quit". It will
# display the current board, wait for a command, and then execute the
# corresponding action.
play_chess() {
    local cmd arg

    while true; do
        show_board
        show_prompt
        case "$cmd" in
            h|help) help_command;;
            b|black) toggle_player;;
            c|coordenates) toggle_coordinates;;
            f|flip) toggle_board_flipped;;
            r|reset) reset_board;;
            default) set_default;;
            raw) set_raw;;
            utf8) set_utf8;;
            fen) fen_command "$arg";;
            [a-h][1-8][a-h][1-8]) move_piece "$cmd";;
            q|quit) exit_command;;
            *) default_command;;
        esac
    done
}

#
# Show help message.
#
help() {
    cat <<HELP

clichess.sh is a simple interface for command-line chess game.

Usage: $(basename "$0") [-h|--help] [-b|--black] [-c|--show-coordinates] [-f|--flip] [-r|--raw] [-u|--utf8] [<FEN>]

-h, --help        Show this help message and exit
-b, --black       Start the game as black pieces
-c, --coordinates Show the board coordenates
-f, --flip        Start with the board flipped
-r, --raw         Start with the chess pieces in raw format
-u, --utf8        Start with the chess pieces in UTF-8
[<FEN>]           Start the game with a position from a FEN string

HELP
    exit 0
}

# main - Entrypoint for the script.
#
# Parameters:
#   FEN - Optional, a FEN (Forsyth-Edwards Notation) to start the game with.
#
# Options:
#   -h, --help - show this help message and exit.
#   -b, --black - Start the game as black.
#   -c, --coordinates - Show column letters on the board.
#   -f, --flip - Flip the board.
#   -r, --raw  - Show chess pieces in raw format.
#   -u, --utf8 - Show chess pieces in UTF-8.
#
main(){
    local FEN

    while (( $# > 0 )); do
        case "$1" in
            -h|--help) help; break;;
            -b|--black) toggle_player;;
            -c|--coordinates) toggle_coordinates;;
            -f|--flip) toggle_board_flip;;            
            -r|--raw) toggle_raw;;
            -u|--utf8) toggle_utf8;;
            *)
                if [[ "$1" == -* ]]; then
                    echo "Invalid command: $1"
                    exit 1
                else
                    FEN="$1"
                fi
                break
                ;;
        esac
        shift
    done

    # options --utf8 and --raw are mutually exclusive
    if [[ $SHOW_RAW == true ]]; then
        if [[ $USE_UTF8 == true ]]; then
            echo "Options --utf8 and --raw are mutually exclusive."
            exit 1
        else
            toggle_raw
        fi 
    fi

    play_chess "$FEN" # The last argument is the FEN, if given.
}

#
# BEGIN
#
main "$@" || {
    echo "An error occurred."
    exit 1
}
#
# The End
#
