import React from "react";
import { Game } from "./Wow";

function playerCount({ minPlayers, maxPlayers }: Game) {
  if (minPlayers === maxPlayers) {
    const inflection = minPlayers === 1 ? "player" : "players";
    return `${minPlayers} ${inflection}`;
  }
  return `${minPlayers} - ${maxPlayers} players`;
}

function description(game: Game) {
  const players = playerCount(game);
  let desc = game.description || "No description available.";
  desc = desc.endsWith(".") ? desc : desc + ".";
  return `${desc} For ${players}.`;
}

export const GameInfo: React.FC<Game> = (game) => {
  return (
    <div className="game-info">
      <h3 className="game__title">{game.title}</h3>
      <h4 className="game__author">By {game.author}</h4>
      <p className="game__description">{description(game)}</p>
    </div>
  );
};
