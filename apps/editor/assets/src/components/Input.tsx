import * as React from "react";

const Input: React.SFC<any> = props => {
  return <input type="text" className="form-control" {...props} />;
};

export default Input;
