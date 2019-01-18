import * as React from "react";
import { Channel, Socket } from "phoenix";

interface Props {
  socketUrl?: string;
  socketParams?: object;
  channelParams?: object;
  channelName: string;
  children: (channel: Channel, socket: Socket) => React.ReactNode;
}

interface State {
  socket?: Socket;
  channel?: Channel;
}

class PhxChannel extends React.Component<Props, State> {
  readonly state: State = {
    socket: undefined,
    channel: undefined
  };

  componentDidMount() {
    const { socketUrl, socketParams, channelParams, channelName } = this.props;

    const socket = new Socket(socketUrl || "/socket", { params: socketParams });
    socket.connect();

    const channel = socket.channel(channelName, channelParams);
    channel.join();

    this.setState({ socket, channel });
  }

  componentWillUnmount() {
    this.state.socket!.disconnect();
  }

  render() {
    if (this.props.children && this.state.channel && this.state.socket) {
      return this.props.children(this.state.channel, this.state.socket);
    } else {
      return <h1>Hello</h1>;
    }
  }
}

export default PhxChannel;
