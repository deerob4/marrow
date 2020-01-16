import axios from "axios";

const API_ENDPOINT = "/api";

const wrapUrl = (url: string) => API_ENDPOINT + url;

function get(url: string, config: object = {}) {
  return axios.get(wrapUrl(url), config);
}

function post(url: string, params: object = {}, config: object = {}) {
  return axios.post(wrapUrl(url), params, config);
}

function put(url: string, params: object = {}, config: object = {}) {
  return axios.put(wrapUrl(url), params, config);
}

function delete_(url: string, config: object = {}) {
  return axios.delete(wrapUrl(url), config);
}

export function headerConfig(token: string) {
  return { headers: { Authorization: "bearer " + token } };
}

export default { get, post, put, delete: delete_ };
