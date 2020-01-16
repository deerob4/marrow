import { Socket, Channel } from "phoenix";
import { IBoardStructure, ICoord } from "../board/types";
import { IImage } from "../assets/types";

export const enum ChannelActionType {
  CONNECT_TO_SOCKET = "@@channels/CONNECT_TO_SOCKET",

  CONNECT_TO_EDITOR = "@@channels/CONNECT_TO_EDITOR",
  LEAVE_EDITOR = "@@channels/LEAVE_EDITOR",
  CREATE_EDITOR_CHANNEL = "@@/channels/CREATE_EDITOR_CHANNEL",

  CHANNEL_ERROR = "@@channelS/CHANNEL_ERROR"
}

export interface IEditorConnect {
  gameId: number;
  board: IBoardStructure;
  error: string | null;
  source: string;
  headerImageUrl: string;
  images: IImage[];
  isPublic: boolean;
  boardImages: { image: string; tile: ICoord }[];
}

export interface ChannelState {
  socket: Socket | null;
  editorChannel: Channel | null;
  channelConnected: boolean;
}
