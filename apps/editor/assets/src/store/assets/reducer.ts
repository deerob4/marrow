import { Reducer } from "redux";
import { AssetActionType, AssetState } from "./types";
import { ActionType } from "typesafe-actions";
import produce from "immer";
import * as actions from "./actions";
import * as channelActions from "../channels/actions";
import { ChannelActionType } from "../channels/types";

type Action = ActionType<typeof actions> | ActionType<typeof channelActions>;

const initialState: AssetState = {
  audio: {},
  images: {},
  uploading: { images: {}, audio: {} }
};

const reducer = produce<AssetState>((draft: AssetState, action: Action) => {
  switch (action.type) {
    case AssetActionType.UPLOAD_IMAGE_REQUEST:
      draft.uploading.images = action.payload;
      break;

    // We want to remove the dummy uploading image and add the real one in.
    case AssetActionType.UPLOAD_IMAGE_SUCCESS:
      const imageId = action.payload.id;
      delete draft.uploading.images[imageId];
      draft.images[imageId] = { ...action.payload, type: "image" };
      break;

    case ChannelActionType.CONNECT_TO_EDITOR:
      draft.images = action.payload.gameData.images.reduce(
        (images, image) => ({ ...images, [image.id]: image }),
        {}
      );
      break;

    case AssetActionType.DELETE_IMAGE_REQUEST:
      delete draft.images[parseInt(action.payload, 10)];
      break;

    case AssetActionType.RENAME_IMAGE_REQUEST:
      const { id, newName } = action.payload;
      draft.images[id].name = newName;
  }
}, initialState);

export { reducer as assetReducer };
