import * as React from "react";
import { Reference } from "../utils/reference_new";
import Accordion from "./Accordion";
import ReferenceBlock from "./ReferenceBlock";
import styled from "styled-components";

interface Props {
  name: string;
  references: Reference[];
  isShown: boolean;
  toggleShown: () => void;
}

const CategoryContainer = styled.div`
  margin-bottom: 20px;
`;

const ReferenceList: React.SFC<Props> = props => {
  if (!props.references.length) return null;

  return (
    <CategoryContainer>
      <Accordion
        title={props.name}
        isShown={props.isShown}
        toggle={props.toggleShown}>
        {props.references.map(ref => (
          <ReferenceBlock key={ref.name} reference={ref} />
        ))}
      </Accordion>
    </CategoryContainer>
  );
};

export default ReferenceList;
