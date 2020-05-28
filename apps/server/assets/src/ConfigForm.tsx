import React from "react";
import { useReducer } from "react";
import { action, ActionType } from "typesafe-actions";
import SpinnerButton from "./SpinnerButton";

export interface Config {
  isPublic: boolean;
  allowSpectators: boolean;
  password: string | null;
  waitTime: number;
}

interface FormState extends Config {
  isValid: boolean;
}

enum ConfigMsg {
  SetIsPublic = "SET_IS_PUBLIC",
  SetAllowSpectators = "SET_ALLOW_SPECTATORS",
  SetPassword = "SET_PASSWORD",
  SetWaitTime = "SET_WAIT_TIME",
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
  },
  setWaitTime(waitTime: number) {
    return action(ConfigMsg.SetWaitTime, waitTime);
  },
};

type ConfigAction = ActionType<typeof ConfigActions>;

function updateConfig(config: FormState, action: ConfigAction): FormState {
  switch (action.type) {
    case ConfigMsg.SetIsPublic:
      return {
        ...config,
        isPublic: action.payload,
        isValid: true,
        password: null,
      };

    case ConfigMsg.SetAllowSpectators:
      return { ...config, allowSpectators: action.payload };

    case ConfigMsg.SetPassword:
      return {
        ...config,
        password: action.payload,
        isValid: action.payload === null || action.payload.length >= 6,
      };

    case ConfigMsg.SetWaitTime:
      let waitTime = action.payload;
      return {
        ...config,
        waitTime,
        isValid: waitTime >= 5 && waitTime <= 120,
      };
  }
}

const defaultConfig: FormState = {
  isPublic: false,
  allowSpectators: false,
  password: null,
  isValid: true,
  waitTime: 60,
};

interface ConfigProps {
  isFetching: boolean;
  onSubmit: (config: Config) => void;
}

export const ConfigForm: React.FC<ConfigProps> = (props) => {
  const {
    setIsPublic,
    setAllowSpectators,
    setPassword,
    setWaitTime,
  } = ConfigActions;
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
            onChange={(e) => dispatch(setIsPublic(e.currentTarget.checked))}
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
            onChange={(e) => dispatch(setAllowSpectators(e.currentTarget.checked))}
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
              onChange={(e) => dispatch(setPassword(e.currentTarget.value))}
            />
          </div>
        )}

        <div className="form-group mb-2 mt-3">
          <label htmlFor="waitTime">
            Seconds between the minimum player count being reached and the game
            starting (5 - 120):
          </label>

          <input
            type="number"
            id="waitTime"
            value={config.waitTime}
            min="5"
            max="120"
            className="form-control"
            onChange={(e) => {
              const waitTime = e.currentTarget.value;
              const waitTimeInt = parseInt(waitTime, 10) || 5;
              dispatch(setWaitTime(waitTimeInt));
            }}
          />
        </div>

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
