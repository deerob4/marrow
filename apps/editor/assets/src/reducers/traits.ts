import { Map } from "immutable";
import ActionTypes from "../constants";
import { Action, Trait, TraitMap, Traits, Path } from "../types";
import cantor from "../utils/cantor";
import { compose } from "ramda";

type TraitType = any;

const updateTraits = (
  traits: Trait<TraitType>[],
  update: (t: Traits, i: TraitType) => Traits
) => (traitMap: TraitMap) => {
  return traits.reduce((map, trait) => {
    const hash = cantor(trait.coord.x, trait.coord.y);
    return map.update(hash, (t) => update(t, trait.value));
  }, traitMap);
};

const setPaths = (paths: Path[]) => (traitMap: TraitMap) => {
  return paths.reduce((tm, path) => {
    const fromHash = cantor(path.from.x, path.from.y);
    return tm.update(fromHash, (t) => ({ ...t, pathLine: path }));
  }, traitMap);
};

// function setPaths(paths: Path[], traitMap: TraitMap) {
//   paths.reduce((x, y) => {
//     return x;
//   }, traitMap)
// }

function traits(state: TraitMap = Map(), action: Action) {
  switch (action.type) {
    case ActionTypes.RECOMPILE_SUCCESS:
      const { images, labels, audio, board } = action.payload;
      let newState = compose(
        updateTraits(images, (t, image) => ({ ...t, image })),
        updateTraits(audio, (t, audio) => ({ ...t, audio })),
        updateTraits(labels, (t, labels) => ({ ...t, labels }))
      )(Map());
      return setPaths(board.paths)(newState);

    case ActionTypes.EDITOR_CONNECT_SUCCESS:
      let s = compose(
        updateTraits(action.payload.imageTraits, (t, image) => ({
          ...t,
          image
        })),
        updateTraits(action.payload.labelTraits, (t, labels) => ({
          ...t,
          labels
        }))
      )(Map());
      return setPaths(action.payload.board.paths)(s);

    default:
      return state;
  }
}

export default traits;
