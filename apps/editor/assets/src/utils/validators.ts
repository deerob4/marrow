import axios from 'axios';
import * as _validate from 'validate.js';

// Typings aren't all there for validate.js, so create
// a custom version that satisfies the compiler.
var validate = _validate;

/**
 * Ensures that the value passed is `true`, otherwise
 * returns an error string.
 * @param {boolean} value - Value to check.
 */
function isTrue(value: boolean) {
  if (value) return;
  return 'must be accepted';
}

/**
 * Calls the server to check that the user's
 * email hasn't already been taken.
 * @param {string} email - Email to validate.
 */
function uniqueEmail(email: string) {
  var address = `/api/account/validate?email=${email}`;
  return uniqueValidation(email, address);
}

/**
 * Generic async function for ensuring that a field is unique.
 * Hooks into validate.js so that it can be used as a constraint.
 * Will only make the request if `field` isn't blank.
 *
 * @param {string} field - The value to validate.
 * @param {string} address - The API address to call to validate uniqueness.
 */
function uniqueValidation(field: string, address: string) {
  // @ts-ignore
  return new validate.Promise((resolve: any, reject: any) => {
    if (!field) resolve();

    if (field.trim().length) {
      axios.get(address)
        .then(r => {
          if (r.data.data.isUnique) {
            resolve();
          } else {
            resolve(' has already been taken');
          }
        })
        .catch(e => reject(e));
    } else {
      resolve();
    }
  });
}

// Register all the custom validators with validate and export it,
// so we can use it in all the other modules.
validate.validators.uniqueEmail = uniqueEmail;
validate.validators.isTrue = isTrue;

export default validate;
