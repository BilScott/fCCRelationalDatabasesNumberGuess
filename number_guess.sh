#!/bin/bash
# Database connection details using the provided PSQL command format
PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"

# Function to play the game
play_game() {
  # Generate a random number between 1 and 1000
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  GUESS_COUNT=0

  echo "Guess the secret number between 1 and 1000:"

  while true; do
    read GUESS
    GUESS_COUNT=$((GUESS_COUNT + 1))

    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
    elif [[ $GUESS -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
      break
    fi
  done

  # Update games_played and best_game in the database
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $GUESS_COUNT < best_game THEN $GUESS_COUNT ELSE best_game END WHERE username = '$USERNAME'")
}

# Prompt user for a username
echo "Enter your username:"
read USERNAME

# Check if the username exists in the database
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  # If user doesn't exist, create new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # If user exists, welcome them back with their stats
  echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    # Ensure correct grammar for "games" and "guesses"
    if [[ $GAMES_PLAYED -eq 1 ]]
    then
      GAMES_WORD="game"
    else
      GAMES_WORD="games"
    fi

    if [[ $BEST_GAME -eq 1 ]]
    then
      GUESSES_WORD="guess"
    else
      GUESSES_WORD="guesses"
    fi

    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED $GAMES_WORD, and your best game took $BEST_GAME $GUESSES_WORD."
  done
fi

# Play the game
play_game
