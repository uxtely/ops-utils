#!/usr/bin/env node
import fs from 'fs';
import { dirname, join, resolve } from 'path'
import { reIsSourceCode, read } from '../nodejs-fs-utils.js'


/**
 * This is just for manually analyzing dependencies.
 * e.g. see what can be consolidated, finding dead files, etc.
 */

const DIR = resolve('../../AppSPA/src');

const importPathRegex = /from\W'.*\.js'/g; // imports with .js extension

console.log(reportDependantCount());


function reportDependantCount() {
	const graph = indexDependants();
	const res = [];
	for (const fpath in graph)
		res.push([fpath, graph[fpath].length]);

	return res
		.filter(([, count]) => count === 0)
	// .sort((a, b) => a[1] - b[1]) // by count
	// .reverse()
}


/**
 * A dictionary with the file path and the ones that import it.
 * {
 *  'DIR/dashboard.js': [],
 *  'DIR/app/App.js': ['DIR/dashboard.js'],
 * 	'DIR/home/Home.js': ['DIR/app/App.js'],
 * 	...
 * }
 */
function indexDependants() {
	const out = {};
	const deps = indexDependecies();

	for (const fpath in deps)
		for (const d of deps[fpath]) {
			out[d] = out[d] || [];
			out[d].push(fpath);
		}

	for (const fpath in deps)
		if (!(fpath in out))
			out[fpath] = [];

	return out;
}


/**
 * Extracts the imports used in each file.
 * { 'DIR/home/Home.js': ['DIR/strings/tr.js', 'DIR/utils/React.js'], ... }
 */
function indexDependecies() {
	const tree = indexSourceFiles();
	const out = {};

	for (const fpath in tree) {
		const match = tree[fpath].match(importPathRegex);
		const currFileDir = dirname(fpath);
		out[fpath] = match
			? match.map(m => join(currFileDir, m.replace("from '", '').replace(/'$/, '')))
			: [];
	}
	return out;
}


/**
 * Creates a dictionary of the source tree.
 * { [path]: fileAsText, ... }
 */
function indexSourceFiles(dir = DIR, dict = {}) {
	for (const f of fs.readdirSync(dir)) {
		const fPath = join(dir, f);
		if (fs.statSync(fPath).isDirectory())
			indexSourceFiles(fPath, dict);
		else if (reIsSourceCode.test(fPath))
			dict[fPath] = read(fPath);
	}
	return dict;
}

