import { Card, Action } from "../types";
import ActionType from "../constants";

export default function cards(state: Card[] = [], action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.cards;

    case ActionType.EDITOR_LEAVE:
      return [];

    default:
      return state;
  }
}
