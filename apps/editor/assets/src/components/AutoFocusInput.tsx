import React from "react";

type Props = React.InputHTMLAttributes<HTMLInputElement>;

class AutoFocusInput extends React.Component<Props> {
  inputRef: React.RefObject<HTMLInputElement>;

  constructor(props: Props) {
    super(props);
    this.inputRef = React.createRef();
  }

  componentDidMount() {
    const node = this.inputRef.current;

    if (node) {
      node.focus();
      node.selectionStart = 0;
    }
  }

  render() {
    return <input ref={this.inputRef} {...this.props} />;
  }
}

export default AutoFocusInput;
