import { Reducer } from "redux";
import { ChannelActionType, ChannelState } from "./types";
import { ActionType } from "typesafe-actions";
import * as actions from "./actions";

type Action = ActionType<typeof actions>;

const initialState: ChannelState = {
  socket: null,
  editorChannel: null,
  channelConnected: false
};

const reducer: Reducer<ChannelState> = (
  state = initialState,
  action: Action
) => {
  switch (action.type) {
    case ChannelActionType.CONNECT_TO_SOCKET:
      return { ...state, socket: action.payload };

    case ChannelActionType.CONNECT_TO_EDITOR:
      return {
        ...state,
        editorChannel: action.payload.channel,
        channelConnected: true
      };

    case ChannelActionType.LEAVE_EDITOR:
      return { ...state, editorChannel: null, channelConnected: false };

    case ChannelActionType.CREATE_EDITOR_CHANNEL:
      return { ...state, editorChannel: action.payload };

    default:
      return state;
  }
};

export { reducer as channelReducer };
