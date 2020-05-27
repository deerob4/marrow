import React from "react";

type headerType = "inside" | "outside";

interface Props {
  title: string;
  headerType: headerType;
}

const Card: React.SFC<Props> = ({ title, headerType, children }) => {
  function renderOutsideHeader(headerType: headerType) {
    if (headerType !== "outside") return null;
    return <div className="card-header">{title}</div>;
  }

  function renderInsideHeader(headerType: headerType) {
    if (headerType !== "inside") return null;
    return <h4 className="card-title">{title}</h4>;
  }

  return (
    <div className="card" style={{ borderTop: "none", overflowY: "scroll" }}>
      {renderOutsideHeader(headerType)}
      <div className="card-body">
        {renderInsideHeader(headerType)}
        {children}
      </div>
    </div>
  );
};

export default Card;
