import React from "react";

const Input: React.FC<any> = (props) => {
  return <input type="text" className="form-control" {...props} />;
};

export default Input;
