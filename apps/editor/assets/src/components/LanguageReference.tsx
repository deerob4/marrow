import * as React from "react";
import Card from "./Card";
import ReferenceList from "./ReferenceList";
import {
  references,
  RefType,
  Reference,
  filterByKind,
  filterByString
} from "../utils/reference_new";

const LanguageReference: React.SFC<{}> = () => {
  const [searchStatus, setSearchStatus] = React.useState({
    searching: false,
    query: "",
    results: []
  });

  const [openBlocks, setOpenBlocks] = React.useState([]);
  const [prevOpenBlocks, setPrevOpenBlock] = React.useState(openBlocks);

  function createRefList(type: RefType, references: Reference[]) {
    return (
      <ReferenceList
        name={type}
        references={filterByKind(type, references)}
        // @ts-ignore
        isShown={openBlocks.includes(type)}
        toggleShown={() => toggleCategory(type)}
      />
    );
  }

  function allRefLists(references: Reference[]) {
    return (
      <>
        {createRefList(RefType.Block, references)}
        {createRefList(RefType.Property, references)}
        {createRefList(RefType.Command, references)}
        {createRefList(RefType.Function, references)}
        {createRefList(RefType.Callback, references)}
        {createRefList(RefType.GlobalVar, references)}
      </>
    );
  }

  function handleFilter(e: React.FormEvent<HTMLInputElement>) {
    const query = e.currentTarget.value;

    if (query.trim() === "") {
      setSearchStatus({ searching: false, query, results: [] });
      setOpenBlocks(prevOpenBlocks);
    } else {
      const results = filterByString(query.toLowerCase(), references);
      // @ts-ignore
      setSearchStatus({
        searching: true,
        query,
        results
      });
      // @ts-ignore
      setOpenBlocks(results.map(r => r.kind));
    }
  }

  function toggleCategory(category: RefType) {
    // @ts-ignore
    if (openBlocks.includes(category)) {
      const blocks = openBlocks.filter(b => b !== category);
      setOpenBlocks(blocks);
      setPrevOpenBlock(blocks);
    } else {
      const blocks = [category, ...openBlocks];
      // @ts-ignore
      setOpenBlocks(blocks);
      // @ts-ignore
      setPrevOpenBlock(blocks);
    }
  }

  function renderSearchResults() {
    if (!searchStatus.results.length) {
      return (
        <p>
          No results found for "{searchStatus.query}
          ".
        </p>
      );
    }

    return allRefLists(searchStatus.results);
  }

  return (
    <Card title="Language Reference" headerType="outside">
      <>
        <input
          type="text"
          className="form-control mb-3"
          placeholder="Filter..."
          autoCapitalize="off"
          value={searchStatus.query}
          onChange={handleFilter}
        />
        {searchStatus.searching
          ? renderSearchResults()
          : allRefLists(references)}
      </>
    </Card>
  );
};

export default LanguageReference;
