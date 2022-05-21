import { join, parse } from 'path'
import { createHash } from 'crypto'
import { readFileSync, mkdirSync, copyFileSync, readdirSync } from 'fs'


/**
 * Copies a dir, depth=1, replacing the filenames with a hash in the target
 *   foo.png      -> <png-hash>.png
 *   foo.png.webp -> <png-hash>.png.webp
 *   foo.png.avif -> <png-hash>.png.avif
 *
 * Yes, both use the SHA-1 from the original PNG. That way
 * in nginx.conf we can conditionally serve the best format.
 *   https://blog.uidrafter.com/conditional-avif-for-video-posters
 *
 * We don't use JPGs (explained in ./media-optimizer.sh)
 */
export function copyDirWithHashedNames(src, dest) {
	mkdirSync(dest, { recursive: true })
	const mediaHashes = new Map()

	for (const file of listFiles(src, /\.(png|mp4)$/)) {
		const { name, base, ext } = parse(file)
		const newFileName = name + '-' + sha1(file) + ext
		const newFile = join(dest, newFileName)
		mediaHashes.set(base, newFileName)
		copyFileSync(file, newFile)

		if (file.endsWith('.png')) {
			copyFileSync(`${file}.webp`, `${newFile}.webp`)
			copyFileSync(`${file}.avif`, `${newFile}.avif`)
		}
	}

	return mediaHashes
}


/**
 * For using the SHA-1 hashes as filenames in HTML.
 * If you want to handle CSS files, edit the regex so
 * instead of checking `="` (e.g. src="img.png") also checks for `url(`
 *
 * Assumes that all the files are in "media/" (not ../media, ./media)
 **/
export function remapHtmlMedia(mediaHashes, html) {
	const reFindMedia = new RegExp('(="media/.*?)"', 'g')
	const reFindMediaKey = new RegExp('="media/')

	for (const [, url] of html.matchAll(reFindMedia)) {
		const hashedName = mediaHashes.get(url.replace(reFindMediaKey, ''))
		if (!hashedName)
			throw `ERROR: Missing ${url}\n`
		html = html.replace(url, `="media/${hashedName}`)
	}
	return html
}


function sha1(f) {
	return createHash('sha1').update(readFileSync(f)).digest('base64url')
}

function listFiles(dir, regex) {
	return readdirSync(dir)
		.filter(f => regex.test(f))
		.map(f => join(dir, f))
}

