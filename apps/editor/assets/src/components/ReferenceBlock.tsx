import React from "react";
import * as ReactMarkdown from "react-markdown";

import {
  Reference,
  RefType,
  RefInfo,
  Block,
  Function,
  Property,
  Command,
  GlobalVar,
  Callback,
  AllowedInside,
} from "../utils/reference_new";

import {
  typeToString,
  formatFunction,
  formatArgList,
  MarrowType,
} from "../utils/marrow_type";

import { Badge, BadgeSeparator } from "./Badge";

const Reference: React.SFC<{}> = (props) => {
  return (
    <>
      <div className="reference">{props.children}</div>
      <hr />
    </>
  );
};

const Name: React.SFC<{ name: string }> = ({ name }) => (
  <h6 className="reference__name">{name}</h6>
);

const Details: React.SFC<{ details: string }> = ({ details }) => (
  // <p className="reference__details">
  <ReactMarkdown className="reference__details" source={details} />
  // </p>
);

const Type: React.SFC<{ type: MarrowType }> = ({ type }) => (
  <BadgeSeparator amount={2}>
    <Badge text={typeToString(type)} type="secondary" />
  </BadgeSeparator>
);

const Requirements: React.SFC<{ required: boolean }> = ({ required }) => {
  if (!required) return null;

  return (
    <BadgeSeparator amount={2}>
      <Badge text="required" type="secondary" />
    </BadgeSeparator>
  );
};

const Example: React.SFC<{ example?: string }> = ({ example }) => {
  if (!example) return null;

  return (
    <>
      <h5>Example</h5>
      <ReactMarkdown source={example} />
    </>
  );
};

const Signature: React.SFC<{
  args: MarrowType[];
  returnType: MarrowType;
}> = (props) => {
  return (
    <span className="reference__type">
      {formatFunction(props.args, props.returnType)}
    </span>
  );
};

const ArgumentList: React.SFC<{ args: MarrowType[] }> = ({ args }) => {
  return <span className="reference__type">{formatArgList(args)}</span>;
};

const AllowedInside: React.SFC<{ allowed: AllowedInside }> = ({ allowed }) => {
  const allowedStr =
    allowed.kind === "specific" ? allowed.block : "events and triggers";

  return <p className="property_allowed_inside">Allowed in: {allowedStr}</p>;
};

const BlockReference: React.SFC<{ block: Block & RefInfo }> = ({ block }) => (
  <Reference>
    <Name name={block.name} />
    <Requirements required={block.required} />
    <Details details={block.details} />
  </Reference>
);

const PropertyReference: React.SFC<{ property: Property & RefInfo }> = ({
  property,
}) => (
  <Reference>
    <Name name={property.name} />
    <Type type={property.type} />
    <AllowedInside allowed={property.allowedInside} />
    <Details details={property.details} />
  </Reference>
);

const FunctionReference: React.SFC<{ func: Function & RefInfo }> = ({ func }) => (
  <Reference>
    <Name name={func.name} />
    <Signature {...func} />
    <Details {...func} />
    {/* <Example {...func} /> */}
  </Reference>
);

const CallbackReference: React.SFC<{ callback: Callback & RefInfo }> = ({
  callback,
}) => (
  <Reference>
    <Name name={callback.name} />
    <ArgumentList args={callback.args} />
    <Details details={callback.details} />
  </Reference>
);

const CommandReference: React.SFC<{ command: Command & RefInfo }> = ({
  command,
}) => (
  <Reference>
    <Name name={command.name} />
    <ArgumentList args={command.args} />
    <AllowedInside allowed={command.allowedInside} />
    <Details details={command.details} />
  </Reference>
);

const GlobalVarReference: React.SFC<{ globalVar: GlobalVar & RefInfo }> = ({
  globalVar,
}) => (
  <Reference>
    <Name name={globalVar.name} />
    <Type type={globalVar.type} />
    <Details details={globalVar.details} />
  </Reference>
);

interface Props {
  reference: Reference;
}

const ReferenceBlock: React.SFC<Props> = ({ reference }) => {
  switch (reference.kind) {
    case RefType.Block:
      return <BlockReference block={reference} />;
    case RefType.Property:
      return <PropertyReference property={reference} />;
    case RefType.Command:
      return <CommandReference command={reference} />;
    case RefType.Function:
      return <FunctionReference func={reference} />;
    case RefType.GlobalVar:
      return <GlobalVarReference globalVar={reference} />;
    case RefType.Callback:
      return <CallbackReference callback={reference} />;
  }
};

export default ReferenceBlock;
