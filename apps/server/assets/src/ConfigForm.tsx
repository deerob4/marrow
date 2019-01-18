import * as React from "react";
import { useReducer } from "react";
import { action, ActionType } from "typesafe-actions";
import SpinnerButton from "./SpinnerButton";

export interface Config {
  isPublic: boolean;
  allowSpectators: boolean;
  password: string | null;
}

interface FormState extends Config {
  isValid: boolean;
}

enum ConfigMsg {
  SetIsPublic = "SET_IS_PUBLIC",
  SetAllowSpectators = "SET_ALLOW_SPECTATORS",
  SetPassword = "SET_PASSWORD"
}

const ConfigActions = {
  setPassword(password: string | null) {
    return action(ConfigMsg.SetPassword, password);
  },
  setIsPublic(isPublic: boolean) {
    return action(ConfigMsg.SetIsPublic, isPublic);
  },
  setAllowSpectators(allowSpectators: boolean) {
    return action(ConfigMsg.SetAllowSpectators, allowSpectators);
  }
};

type ConfigAction = ActionType<typeof ConfigActions>;

function updateConfig(config: FormState, action: ConfigAction): FormState {
  switch (action.type) {
    case ConfigMsg.SetIsPublic:
      return { ...config, isPublic: action.payload, isValid: true, password: null };

    case ConfigMsg.SetAllowSpectators:
      return { ...config, allowSpectators: action.payload };

    case ConfigMsg.SetPassword:
      return {
        ...config,
        password: action.payload,
        isValid: action.payload === null || action.payload.length >= 6
      };
  }
}

const defaultConfig: FormState = {
  isPublic: false,
  allowSpectators: false,
  password: null,
  isValid: true
};

interface ConfigProps {
  isFetching: boolean;
  onSubmit: (config: Config) => void;
}

export const ConfigForm: React.SFC<ConfigProps> = props => {
  const { setIsPublic, setAllowSpectators, setPassword } = ConfigActions;
  const [config, dispatch] = useReducer(updateConfig, defaultConfig);

  function onRequirePassword(e: React.FormEvent<HTMLInputElement>) {
    const passwordIsRequired = e.currentTarget.checked;

    if (passwordIsRequired) {
      dispatch(setPassword(""));
    } else {
      dispatch(setPassword(null));
    }
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const { isValid, ...fields } = config;
    props.onSubmit(fields);
  }

  return (
    <form onSubmit={handleSubmit}>
      <fieldset disabled={props.isFetching}>
        <div className="form-group form-check mb-1">
          <input
            type="checkbox"
            className="form-check-input"
            id="isPublic"
            checked={config.isPublic}
            onChange={e => dispatch(setIsPublic(e.currentTarget.checked))}
          />
          <label htmlFor="isPublic" className="form-check-label">
            List publicly?
          </label>
        </div>

        <div className="form-group form-check mb-1">
          <input
            type="checkbox"
            className="form-check-input"
            id="allowSpectators"
            checked={config.allowSpectators}
            onChange={e => dispatch(setAllowSpectators(e.currentTarget.checked))}
          />
          <label htmlFor="allowSpectators" className="form-check-label">
            Allow spectators?
          </label>
        </div>

        <div className="form-group form-check mb-2">
          <input
            type="checkbox"
            className="form-check-input"
            id="requirePassword"
            disabled={config.isPublic}
            checked={config.password !== null}
            onChange={onRequirePassword}
          />
          <label htmlFor="requirePassword" className="form-check-label">
            Require password to join?
          </label>
        </div>

        {config.password !== null && (
          <div className="form-group mb-2">
            <label htmlFor="password">Password (at least 6 characters)</label>
            <input
              type="password"
              id="password"
              className="form-control"
              value={config.password}
              onChange={e => dispatch(setPassword(e.currentTarget.value))}
            />
          </div>
        )}

        <SpinnerButton
          className="mt-2"
          element={{ type: "submit", disabled: !config.isValid }}
          isSpinning={props.isFetching}
          text="Host Game"
        />
      </fieldset>
    </form>
  );
};
