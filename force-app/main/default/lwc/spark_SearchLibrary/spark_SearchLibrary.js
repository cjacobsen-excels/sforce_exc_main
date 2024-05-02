/**
 * Options examples:
 * { threashold: 1, // Return all results
 *   searchChildren: false, // Only search parent object
 *   fields: [
 *     {name: 'FirstName', weight: 2 },
 *     {name: 'Account.Name', weight: 1}
 *   ] // Matches on first name are worth double that of matches on the related account's name
 * }
 */

class spark_SearchLibrary {
  /**
   * @todo: Implement field weight
   * @todo: implement ignoring location for longtext fields; default short text fields to weight 2
   * @todo: implement match object for highlighting the matched text
   * @todo: highlightMatches option (inserts HTML into field text)
   */
  options = {
    threshold: .6, // Max score for an item to be a match (0 is exact match, 1 is complete miss)
    sortScore: true,
    ignoreLength: true, // Score is impacted by the length of the field
    minMatchLength: 1, // Minimum number of matching characters
    caseSensitive: false,
    searchChildren: false,
    fields: null, // Array of field names to search through. Will not be used when searching children
    ignoreLocation: false, // Ignore the distance a match is from the start of the string
    stopOnMatch: false, // When the match threshold is passed, stop searching the item.
    // Not recommended when sorting by score.
    includeMatches: true,
    distance: 100, // The maximum distance between parts of a search before it is considered a miss
    skipTypes: ['ID', 'BOOLEAN', 'BASE64', 'URL', 'REFERENCE', 'ENCRYPTEDSTRING'] // Field types to ignore
      // Only used when options.fields is not specified
  }

  originalViewModel;
  searcher;

  constructor() {}

  initialize(fieldDescribes, options) {
    if (this.options.fields === null && fieldDescribes) this.options.fields = this.buildFieldset(fieldDescribes);
  }

  search(query, items, limit) {
    if (!limit) limit = -1;
    if (query.length === 0) return items;

    this.searcher = this.createSearcher(query);
    if (this.options.fields === null) throw 'No fields specified and no field describe set';
    const searchHandler = (this.options.searchChildren) ? this.recursiveSearch() : this.shallowSearch();
    let results = [];
    for (let item of items) {
      let searchResult = searchHandler(query, item);
      //if (searchResult.isMatch && searchResult.score <= this.options.threshold) {
      searchResult.record = item;
      item.properties.score = searchResult.score;
      console.log(item.properties.score);
      if (this.options.sortScore) {
        results.push(searchResult);
      } else {
        results.push(item);
      }
      //}
    }

    if (this.options.sortScore) {
      results = results.sort((a, b) => a.score - b.score).map(v => v.record);
    }

    if (limit > 0 && results.length > limit) {
      return results.slice(0, limit);
    }
    return results;
  }

  createSearcher(query) {
    return new BitapSearch(query, this.options);
  }

  buildFieldset(fieldDescribes) {
    return Object.keys(fieldDescribes)
      .filter(v => this.options.skipTypes.indexOf(fieldDescribes[v].type) === -1)
      .map(v => v.toLowerCase());
  }

  /* Not used yet - would need future enhancement
  buildSubqueryFieldset(subQueries) {
    let arr = [];
    for (let subQuery of subQueries) {
      arr.concat(this.buildFieldset(subQuery.fieldDescribes));
    }
    arr = this.arrayUnique(arr);
    return arr;
  }


  arrayUnique(array) {
    var a = array.concat();
    for (var i = 0; i < a.length; ++i) {
      for (var j = i + 1; j < a.length; ++j) {
        if (a[i] === a[j])
          a.splice(j--, 1);
      }
    }
    return a;
  }*/


  /**
   * Search handler used when searching a record's children.
   * All search scores will bubble up to the parent record.
   * Currently incapable of searching or weighing specific fields in the children.
   */
  recursiveSearch() {
    let $this = this;
    return (query, item) => {
      let itemResults = new SearchResult();
      itemResults.score = 1;
      itemResults.isMatch = false;
      for (let key of $this.options.fields) {
        $this.doSearch(itemResults, query, item, key); // This mutates itemResults
      }
      if (item.children.length > 0) {
        $this.doRescursiveSearch(itemResults, query, item);
      }
      return itemResults;
    }
  }


  /**
   * Does the search of child records recursively.
   */
  doRescursiveSearch(itemResults, query, item) {
    for (let childItem of item.children) {
      for (let key in childItem.value) { //@todo: allow config to specify subquery fields to use
        this.doSearch(itemResults, query, childItem, key);
      }
      if (childItem.children.length > 0) {
        this.doRescursiveSearch(itemResults, query, childItem);
      }
    }
  }


  /**
   * Search handler for searching only the top-most record set. This will search
   * lookup fields, but will not search related records. For example, Let's say a Contact
   * belongs to an account and owns several opportunities. This search can be used
   * to include the contact's fields and the accounts fields. This would not search
   * the related opportunities. Recursive search will.
   */
  shallowSearch() {
    let $this = this;
    return (query, item) => {
      let itemResults = new SearchResult();
      itemResults.score = 1;
      itemResults.isMatch = false;
      for (let key of $this.options.fields) {
        $this.doSearch(itemResults, query, item, key);
      }
      return itemResults;
    }
  }


  /**
   * Gets a string value from a record, runs a bitap search on that string value, and 
   * mutates the item's search results if the match score increases.
   */
  doSearch(itemResults, query, item, key) {
    let val = this.getValueFromPath(item.value, key);
    if (typeof val === 'undefined' || val === null) return itemResults;
    val = '' + val;
    let searchResult = this.searcher.searchIn(val);
    // @todo: Handle searchResult.indices for text highlighting
    itemResults.score = Math.min(searchResult.score, itemResults.score);
    if (!itemResults.isMatch && searchResult.score <= this.options.threshold) itemResults.isMatch = true;
  }


  /**
   * Method for getting a value from nested objects based on the string path. Returns null
   * when the object does not contain the given key path.
   * @param {Object} variable - Nested objects which can be traversed (ex. {Contact: {Name: 'John'}})
   * @param {String} path - The path to target data (ex. 'Contact.Name')
   */
  getValueFromPath(variable, path) {
    try {
      return this.walkPath(variable, path.split('.').reverse());
    } catch (e) {
      return null;
    }
  }

  walkPath(scope, pathArray) {
    const searchKey = pathArray.pop();
    const nextScope = scope[Object.keys(scope).find(key => key.toLowerCase() === searchKey)];
    if (pathArray.length === 0) {
      return nextScope;
    } else {
      return this.walkPath(nextScope, pathArray);
    }
  }


}

class BitapSearch {
  chunks;
  options;
  constructor(query, options) {
    this.options = options;
    this.chunks = [];
    const addChunk = (query, startIndex) => {
      this.chunks.push({
        query,
        alphabet: createQueryAlphabet(query),
        startIndex
      });
    };

    this.query = options.caseSensitive ? query : query.toLowerCase();
    if (this.query.length > MAX_LENGTH) { // query longer than 32? Create multiple chunks
      let i = 0;
      const remainder = len % MAX_LENGTH;
      const end = len - remainder;

      while (i < end) {
        addChunk(this.query.substr(i, MAX_LENGTH), i);
        i += MAX_LENGTH;
      }

      if (remainder) {
        const startIndex = len - MAX_LENGTH;
        addChunk(this.query.substr(startIndex), startIndex);
      }

    } else {
      addChunk(this.query, 0)
    }

  }

  /**
   * Prepares a bitap search on a string, runs optimization checks and 
   * hands off the search to the search handler.
   * @param String text - text to perform bitap search on
   * @returns search result from bitap search
   */
  searchIn(text) {
    if (!this.options.caseSensitive) {
      text = text.toLowerCase();
    }
    //Handle exact match
    if (this.query === text) {
      let result = {
        isMatch: true,
        score: 0
      }
      if (this.options.includeMatches) {
        result.indices = [
          [0, text.length - 1]
        ];
      }
      return result;
    }

    //Otherwise, run bitap
    let hasMatches = false;
    let totalScore = 0;
    let allIndices = [];
    this.chunks.forEach((chunk) => {
      const { query, alphabet, startIndex } = chunk;
      const { isMatch, score, indices } = this.doSearch(text, query, alphabet, {
        location: startIndex,
        threshold: this.options.threshold,
        minMatchLength: this.options.minMatchLength,
        includeMatches: this.options.includeMatches,
        ignoreLocation: this.options.ignoreLocation
      });

      if (isMatch) {
        hasMatches = true;
      }

      totalScore += score;

      if (isMatch && indices) {
        allIndices = [...allIndices, ...indices];
      }
    });

    let results = new SearchResult();
    results.score = hasMatches ? totalScore / this.chunks.length : 1;
    results.isMatch = hasMatches;
    if (hasMatches && this.options.includeMatches) {
      results.indices = allIndices;
    }

    return results;
  }


  /**
   * Returns a score between 0 and 1 based on the quality of the match.
   */
  computeScore(query, {
    errors = 0,
    currentLocation = 0,
    expectedLocation = 0,
    ignoreLocation = false,
    distance = null
  } = {}) {
    if (query.length === 0) return 0;
    if (distance === null) distance = this.options.distance;
    const accuracy = errors / query.length;
    if (ignoreLocation) {
      return accuracy;
    }
    const proximity = Math.abs(expectedLocation - currentLocation);
    if (!distance) {
      return proximity ? 1.0 : accuracy;
    }
    return accuracy + proximity / distance;
  }

  doSearch(text, query, patternAlphabet, {
    location = 0,
    threshold = 0.6,
    minMatchLength = 1,
    includeMatches = true,
    ignoreLocation = false
  } = {}) {
    const queryLen = query.length;
    const textLen = text.length;
    const expectedLocation = Math.max(0, Math.min(location, textLen));
    let currentThreshold = threshold;
    let bestLocation = expectedLocation;
    const computeMatches = minMatchLength > 1 || includeMatches;
    const matchMask = computeMatches ? Array(textLen) : [];
    let index;

    //Get all exact matches (search optimization)
    while ((index = text.indexOf(query, bestLocation)) > -1) {
      let score = this.computeScore(query, {
        currentLocation: index,
        expectedLocation: expectedLocation,
        ignoreLocation: ignoreLocation
      });

      currentThreshold = Math.min(score, currentThreshold);
      bestLocation = index + queryLen;

      if (computeMatches) {
        let i = 0;
        while (i < queryLen) {
          matchMask[index + i] = 1;
          i += 1;
        }
      }
    }

    // Reset the best location
    bestLocation = -1;
    let lastBitArr = [];
    let finalScore = 1;
    let binMax = queryLen + textLen;
    const mask = 1 << (queryLen - 1);
    for (let i = 0; i < queryLen; i++) {
      let binMin = 0;
      let binMid = binMax;

      while (binMin < binMid) {
        const score = this.computeScore(query, {
          errors: i,
          currentLocation: expectedLocation + binMid,
          expectedLocation: expectedLocation,
          ignoreLocation: ignoreLocation
        });

        if (score <= currentThreshold) {
          binMin = binMid;
        } else {
          binMax = binMid;
        }

        binMid = Math.floor((binMax - binMin) / 2 + binMin);
      }

      //Use the result from this iteration as the maximum for the next
      binMax = binMid;
      let start = Math.max(1, expectedLocation - binMid + 1);
      let finish = Math.min(expectedLocation + binMid, textLen) + queryLen;

      let bitArr = Array(finish + 2);
      bitArr[finish + 1] = (1 << i) - 1;

      for (let j = finish; j >= start; j--) {
        let currentLocation = j - 1;
        let charMatch = patternAlphabet[text.charAt(currentLocation)];
        if (computeMatches) {
          //Quick bool to int type cast
          matchMask[currentLocation] = +!!charMatch;
        }

        // First pass: exact match
        bitArr[j] = ((bitArr[j + 1] << 1) | 1) & charMatch;

        // Second pass: fuzzy match
        if (i) {
          bitArr[j] |= ((lastBitArr[j + 1] | lastBitArr[j]) << 1) | 1 | lastBitArr[j + 1];
        }

        if (bitArr[j] & mask) {
          finalScore = this.computeScore(query, {
            errors: i,
            currentLocation: currentLocation,
            expectedLocation: expectedLocation,
            ignoreLocation: ignoreLocation
          });

          if (finalScore <= currentThreshold) {
            currentThreshold = finalScore;
            bestLocation = currentLocation;
            if (bestLocation <= expectedLocation) {
              break;
            }

            start = Math.max(1, 2 * expectedLocation - bestLocation);
          }
        }
      }

      const score = this.computeScore(query, {
        errors: i + 1,
        currentLocation: expectedLocation,
        expectedLocation: expectedLocation,
        ignoreLocation: ignoreLocation
      });

      if (score > currentThreshold) {
        break;
      }
      lastBitArr = bitArr;
    }

    const result = new SearchResult();
    result.isMatch = bestLocation >= 0;
    result.score = Math.max(0.001, finalScore); // if the final score is 0, bump slightly as it isn't "exact"

    if (computeMatches) {
      const indices = this.convertMaskToIndices(matchMask, minMatchLength);
      if (!indices.length) {
        result.isMatch = false;
      } else if (includeMatches) {
        result.indices = indices;
      }
    }
    return result;
  }

  convertMaskToIndices(matchmask = [], minMatchLength) {
    if (!minMatchLength) minMatchLength = this.options.minMatchLength;
    let indices = [];
    let start = -1;
    let end = -1;
    let i = 0;

    for (let len = matchmask.length; i < len; i += 1) {
      let match = matchmask[i];
      if (match && start === -1) {
        start = i;
      } else if (!match && start !== -1) {
        end = i - 1;
        if (end - start + 1 >= minMatchLength) {
          indices.push([start, end]);
        }
        start = -1;
      }
    }

    if (matchmask[i - 1] && i - start >= minMatchLength) {
      indices.push([start, i - 1]);
    }

    return indices;
  }
}

class SearchResult {
  isMatch;
  score;
  indices;
  record;
}

const MAX_LENGTH = 32;
const createQueryAlphabet = query => {
  let mask = {}

  for (let i = 0, len = query.length; i < len; i += 1) {
    const char = query.charAt(i)
    mask[char] = (mask[char] || 0) | (1 << (len - i - 1))
  }

  return mask
}

const library = new spark_SearchLibrary();
const getLibrary = () => {
  return library;
}
export { getLibrary }