import { combineReducers } from "redux";
import indexById from "../utils/indexById";
import {
  prop,
  assoc,
  dissoc,
  assocPath,
  append,
  filter,
} from "ramda";
import { ById, Action, Asset, ImagesState } from "../types";

import ActionType from "../constants";
import notEquals from "../utils/notEqual";

export function deletingImages(state: number[] = [], action: Action) {
  switch (action.type) {
    case ActionType.DELETE_IMAGE_REQUEST:
      return append(action.payload, state);

    case ActionType.DELETE_IMAGE_SUCCESS:
      return state.filter((id) => id !== action.payload);

    default:
      return state;
  }
}

function byId(state: ById<Asset<"image">> = {}, action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return indexById(action.payload.images);

    case ActionType.UPLOAD_IMAGE_SUCCESS:
      return assoc(action.payload.id, action.payload, state);

    case ActionType.DELETE_IMAGE_SUCCESS:
      return dissoc(action.payload, state);

    case ActionType.RENAME_IMAGE_REQUEST:
    case ActionType.RENAME_IMAGE_SUCCESS:
      const { id, name } = action.payload;
      return assocPath([id, "name"], name, state);

    default:
      return state;
  }
}

type ByName = { [name: string]: number };

function byName(state: ByName = {}, action: Action): ByName {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.images.reduce(
        (images, image) => ({ ...images, [image.name]: image.id }),
        {}
      );

    case ActionType.UPLOAD_IMAGE_SUCCESS:
      return assoc(action.payload.name, action.payload.id, state);

    case ActionType.DELETE_IMAGE_SUCCESS:
      return dissoc(action.payload, state);

    case ActionType.RENAME_IMAGE_SUCCESS:
      const { id, name } = action.payload;
      const withoutOldImage = dissoc(name, state);
      const withNewImage = assoc(name, id, withoutOldImage);

      return withNewImage;

    default:
      return state;
  }
}

function allIds(state: number[] = [], action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.images.map(prop("id"));

    case ActionType.UPLOAD_IMAGE_SUCCESS:
      return append(action.payload.id, state);

    case ActionType.DELETE_IMAGE_SUCCESS:
      return filter(notEquals(action.payload), state);

    default:
      return state;
  }
}

export default combineReducers<ImagesState, Action>({ byId, allIds, byName });
