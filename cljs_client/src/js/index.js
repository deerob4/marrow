import posed, {PoseGroup} from "react-pose";
import * as Phoenix from "phoenix";
import {Presence} from "phoenix";
import ReactSelect from "react-select";
import { wrapGrid } from "animate-css-grid";
import ReactMarkdown from "react-markdown"

window.posed = posed;
window.PoseGroup = PoseGroup;
window.Phoenix = Phoenix;
window.ReactSelect = ReactSelect;
window.wrapGrid = wrapGrid;
window.ReactMarkdown = ReactMarkdown;

window.createPresence = function (channel) {
  console.log(channel);
  const presence = new Presence(channel);
  console.log(presence)
  presence.onSync(() => {
    console.log(presence.list());
  })
};