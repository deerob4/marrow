import { Action, User } from "../types";
import ActionType from "../constants";

const emptyUser: User = {
  id: "",
  name: "",
  email: ""
};

function user(user = emptyUser, action: Action) {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      return action.payload.user;

    default:
      return user;
  }
}

export default user;
